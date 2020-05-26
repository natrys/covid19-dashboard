last=60

ylim() {
  tail -1 $1 | tab 'max.[int.@ : skip(cut(array(@)[0], "\t"), 1)] .. @ / -30.0' 
}

echo "load 'plot.gplot'"

cd data/

for source in *.final; do

  fname="${source%.*}"
  case $fname in
    todayDeath) title='Daily Death' ;;
    todayCases) title='Daily Cases' ;;
    totalDeath) title='Total Death' ;;
    totalCases) title='Total Cases' ;;
  esac

  echo "\
  set ylabel '$fname'
  set title '$title'
  set output '${fname}.png'

  plot [][$(ylim $source):] for [col=2:*] 'data/${source}' using 0:col:xtic(1) every ::(STATS_records - $last) with lines lw 3
  "

done
