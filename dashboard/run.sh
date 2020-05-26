#!/bin/mksh

flatten() {
  sed -E 's/(.*)/\"\1\"/' | paste -s -d,
}

accum() {
  jq -r '.[] | [(.timeline.deaths | map(.)[-2:] | [0, .[-1] - .[0]] | max), .country] | join("\t")' all |  tab 'reverse.sort(flip.{@~1 -> sum(uint.@~0) : cut(@,"\t")})[-20,-1]'
}

dups() {
  jq -r '.[] | select(.province != null) | .country' $1 | sort | uniq
}

sans_dups() {
  cat prepare.jq | sed -e "s|filtered|$(dups $1 | flatten)|" > sans_dups.jq
  jq -f sans_dups.jq $1 > sans_dups.data
}

coalesce_dups() {
  cat coalesce.jq | sed -e "s|filtered|$(dups $1 | sed -E 's/(.*)/coalesce("\1")/' | paste -s -d,)|" > coalesce_dups.jq
  jq -f coalesce_dups.jq $1 > coalesce_dups.data
}

fix_data() {
  sans_dups $1
  coalesce_dups $1
  jq -s add *_dups.data
  rm *_dups.*
}

select_by() {
  case $1 in
    top)
      jq 'sort_by(-.data[-1][-1])[0:10]'
      ;;
    choice)
      echo "map(select(.country | IN(filtered)))" | sed -E "s/filtered/$(flatten < countries)/" > countries.jq
      jq -f countries.jq
      rm countries.jq
      ;;
  esac
}

extract() {
  jq -r '.[] | [ .country ], [ .data | .[] | @tsv ] | .[]' $1
}

generate_header() {
	printf "Date\t" > data/header
	extract $1 | awk '/^[A-Z]/' | sort | paste -sd'\t' >> data/header
}

generate_dates() {
  jq -r '.[0].timeline.cases | to_entries[] | .key' $1 > data/date
}

generate_plot() {
  mkdir -p data/
  generate_dates historical
  generate_header $1
  extract $1 | awk -f savefile.awk
  splice
  mksh plot_command.sh | gnuplot -
}

splice() {
  cd data/

  for item in totalCases totalDeath todayCases todayDeath; do
    cp header $item.final
    paste -d'\t' date ${item}_*.data >> $item.final
  done

  cd ../
}

images() {
  for type in {top,choice}; do
    mkdir -p images/$type/
    make type=$type selected
    generate_plot selected
    mv *.png images/$type/
    make cache_clean
  done
}

world_summary() {
  curl -sL https://api.covid19api.com/world/total > world
  export WDEATH=`jq .TotalDeaths world`
  export WCASES=`jq .TotalConfirmed world`
  rm world
}

project() {
  images
}

lag() {
  jq -r ".[] | [(.data[-$1:] | .[-1][-1], .[0][-1]), .country] | @tsv"
}

show_diff() {
  awk -v OFS="\t" -v FS="\t" '{ print $1 - $2, $3 }' 
}

show_percentage() {
  awk -v c=$1 -v FS="\t" -v OFS="\t" '{ if ($2 > 0) {
    printf "%d\t%d\t%.1f\t%.1f\t%s\n", $1, $2, ($1 - $2) * 100 / $2, ($1 - $2) * 100 / ($2 + c), $3 }
  }' | sort -rn -k 4
}

trending() {
  lag $1 < fixed > trending
  local c=`show_diff < trending | tab 'avg.?[uint.@..@>0,@]'`
  show_percentage $c < trending
  rm trending
}

show_trending() {
  printf "Country\tDeath<br />t0\tDeath<br />t1\tΔ%%\tΔ%%<br />(normalized)\n"
  trending 3 | awk -v FS="\t" -v OFS="\t" '{print $5, $2, $1, $3, $4}' | head -10
}

generate_trending() {
  show_trending | txr export.txr > trending.html
}

diff_table() {
  printf "Country\tDeath (1d)\n" > diff1.data
  lag 2 < fixed | show_diff | sort -rn | head -20 | awk -v IFS="\t" -v OFS="\t" '{print $2, $1}' >> diff1.data
  printf "Country\tDeath (5d)\n" > diff5.data
  lag 6 < fixed | show_diff | sort -rn | head -20 | awk -v IFS="\t" -v OFS="\t" '{print $2, $1}' >> diff5.data
}

generate_diff() {
  diff_table
  #paste -d'\t' diff{5,1}.data | txr export.txr > diff.html
  txr export.txr diff1.data > diff1.html
  txr export.txr diff5.data > diff5.html
  cat diff1.html diff5.html > diff.html
  rm diff?.*
}

generate_index() {
  txr index.txr > index.html
}

clean() {
  make cache_clean
  make data_clean
  make page_clean
}

"$@"
