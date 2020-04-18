.POSIX:

.SUFFIXES:

.PHONY: cache_clean clean images all

all: index.html

index.html: index.txr diff.html trending.html images
	./run.sh generate_index

trending.html: fixed export.txr
	./run.sh generate_trending

diff.html: fixed export.txr
	./run.sh generate_diff

images: images/*/*.png selected

images/%.png: fixed
	./run.sh images

historical:
	curl -sL https://corona.lmao.ninja/v2/historical/?lastdays=1000000 > $@

fixed: historical
	./run.sh fix_data $< > $@

selected: fixed
	./run.sh select_by $(type) < $< > $@

cache_clean:
	rm data/* selected

data_clean:
	rm historical fixed

page_clean:
	rm *.html	
