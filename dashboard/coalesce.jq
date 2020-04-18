def coalesce(country):
  map(select(.country == country)) 
  | map(.timeline | map( map(.) )[0:2] | transpose) 
  | transpose 
  | map(reduce .[] as $it (
          [0, 0]; 
          [ .[0] + $it[0], .[1] + $it[1] ]
        )
    ) 
  | 
  { country: country, data: . } ;

[
  filtered
]
