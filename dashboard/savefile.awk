/^[^0-9]/ {
  country = $0 
  gsub(" ", "_", country)
  next
}

{
  todayCases = $1 - totalCases
  todayDeath = $2 - totalDeath

  todayCases = (todayCases > 0 ? todayCases : 0)
  todayDeath = (todayDeath > 0 ? todayDeath : 0)

  totalCases = $1
  totalDeath = $2

  print totalCases >> ("data/" "totalCases_" country ".data")
  print totalDeath >> ("data/" "totalDeath_" country ".data")
  print todayCases >> ("data/" "todayCases_" country ".data")
  print todayDeath >> ("data/" "todayDeath_" country ".data")
}
