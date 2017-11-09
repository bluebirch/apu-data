# Läs in CSV-filen (som är fixad med perlscriptet)

af <- read.csv("DATA.csv", encoding="UTF-8")

# Konvertera datum (de läses in som faktorer i R)
library(lubridate)
af$ats.date <- ymd(af$ats.date)
af$hts.date <- ymd(af$hts.date)
af$vts.birthdate <- ymd(af$vts.birthdate)

# Jämför födelseår från ATS respektive VTS (HTS har ingen uppgift om födelseår/ålder)
af$birthyear_valid <- af$ats.birthyr - year(af$vts.birthdate) == 0

# Rapportera de rader där födelseåret inte stämmer mellan ATS och VTS (detta skall ordnas med knitr när det väl fungerar)
af.invalid_year <- af[af$birthyear_valid==FALSE & !is.na(af$birthyear_valid),c('tp','ats.birthyr','vts.birthdate','ats.tc','ats.testl')]

library(plyr)

# Vilka testcenter står för felen?
tc.err <- count(af.invalid_year,vars="ats.tc")
tc.err[with(tc.err, order(-freq)),]

# Vilka testledare? Här är det uppenbart att värdet i testl behöver standardiseras av combine-csv.pl. Får fixa det någon dag.
tl.err <- count(af.invalid_year,vars="ats.testl")
tl.err[with(tl.err, order(-freq)),]


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
af$AGE <- age( af$Födelsedatum, af$TESTDAY.Testdatum )

# Gör ett frekvensdiagram (inte historgram!) över åldersfördelningen
plot(as.factor(af$Ålder), col="dark green", xlab="Ålder", ylab="Frekvens")
