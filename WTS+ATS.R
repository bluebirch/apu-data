# Läs in CSV-filen (som är fixad med perlscriptet)

af <- read.csv2("WTS+ATS.csv", encoding="UTF-8")

# Konvertera datum (de läses in som faktorer i R)
af$Födelsedatum <- as.Date(af$Födelsedatum, format="%Y-%m-%d")
af$TESTDAY.Testdatum <- as.Date(af$TESTDAY.Testdatum, format="%Y-%m-%d")

# Funktion för att beräkna ålder (från https://stackoverflow.com/questions/3611314/calculating-ages-in-r)
age = function(from, to) {
  from_lt = as.POSIXlt(from)
  to_lt = as.POSIXlt(to)

  age = to_lt$year - from_lt$year

  ifelse(to_lt$mon < from_lt$mon |
           (to_lt$mon == from_lt$mon & to_lt$mday < from_lt$mday),
         age - 1, age)
}

# Beräkna ålder på personen vid testtillfället
af$Ålder <- age( af$Födelsedatum, af$TESTDAY.Testdatum )

# Gör ett frekvensdiagram (inte historgram!) över åldersfördelningen
plot(as.factor(af$Ålder), col="dark green", xlab="Ålder", ylab="Frekvens")
