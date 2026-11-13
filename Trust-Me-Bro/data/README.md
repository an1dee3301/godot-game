# Party question bank

`questions.json` contains 160 originally worded multiple-choice questions in eight categories, with twenty questions per category. The three difficulty labels contain 56 easy, 56 medium and 48 hard questions. Correct options are stored by index, then shuffled independently for each seeded deck. The deck visits all eight categories in each group of eight questions and never repeats an ID.

Questions use stable facts rather than current rankings, office-holders, disputed superlatives or time-sensitive records. Every question includes a short explanation for the reveal. The online host sends the selected prompt and options; the correct index and explanation are withheld until the reveal. Nerd Glasses hints travel only to their owner.

Primary reference points used while checking subject matter:

- [NASA: the planets](https://science.nasa.gov/solar-system/planets/) and [Apollo 11](https://www.nasa.gov/mission/apollo-11/).
- [IUPAC periodic table](https://iupac.org/what-we-do/periodic-table-of-elements/) and [NIST SI units](https://www.nist.gov/pml/owm/metric-si/si-units).
- [FIDE Laws of Chess](https://handbook.fide.com/chapter/e012023), for board dimensions, starting pieces, legal moves and checkmate.
- [World Athletics: decathlon](https://worldathletics.org/disciplines/combinedevents/decathlon) and [the marathon](https://worldathletics.org/disciplines/road-running/marathon).
- [International Fencing Federation: equipment and disciplines](https://fie.org/fie/structure/administrative-office), with the federation's [Olympic press kit](https://static.fie.org/uploads/9/48878-Olympic%20Press%20Kit%20web%20-%20ENG.pdf) for épée's whole-body target.
- [Olympic rings](https://www.olympics.com/ioc/olympic-rings), for the five-ring symbol.

Other entries use standard school-level arithmetic, geography, biology, literature and music facts. These are original questions rather than a copied trivia collection. Review wording and the corresponding explanation together when editing an entry. In particular, retain qualifications such as "standard", "most of Egypt", "in the three-age system" and "in Euclidean geometry"; they make the expected answer precise.

Run `Godot --headless --path . --script res://tests/quiz_bank_test.gd` to check uniqueness, four distinct options, valid answer indices, category and difficulty coverage, deterministic shuffling, filters and source immutability.
