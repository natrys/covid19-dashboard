def prepare:
{
  country: .country,
  data:
    .timeline
    | map( map(.) )[0:2]
    | transpose
};

map(
  select(.country | IN (
      filtered
    )
    | not
  )
  | prepare
)
