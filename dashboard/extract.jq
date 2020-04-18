def extract:
  .timeline 
  | map( map(.) )[0:2]
  | transpose 
  | .[]  
  | @tsv;

.[] | [ .country ], [ . | extract ] | .[]
