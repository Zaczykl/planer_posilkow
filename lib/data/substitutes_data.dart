/// Lista wymienników — grupy składników, które można stosować zamiennie.
/// Nazwy małymi literami; muszą odpowiadać nazwom używanym w aplikacji.
/// Składnik może należeć do kilku grup (np. tofu, krewetki).
const List<Set<String>> substituteGroups = [
  // ── Źródła węglowodanów ────────────────────────────────────────────────
  // Warzywa (poza strączkowymi i ziemniakami)
  {
    'pomidor', 'pomidorki koktajlowe', 'ogórek', 'ogórek kiszony',
    'papryka czerwona', 'cukinia', 'brokuł', 'marchew', 'rzodkiewka',
    'kapusta czerwona', 'seler naciowy', 'kalafior', 'szparagi zielone',
    'bakłażan', 'dynia', 'pieczarki',
  },
  // Zielone warzywa liściaste
  {
    'szpinak', 'rukola', 'roszponka', 'sałata rzymska', 'miks sałat',
    'jarmuż', 'sałata lodowa',
  },
  // Owoce (zamienniki owoców; świeże ↔ suszone: 150 g świeżych = 20 g suszonych)
  {
    'banan', 'jabłko', 'pomarańcza', 'kaki', 'mandarynki', 'brzoskwinia',
    'gruszka', 'kiwi', 'maliny', 'truskawki', 'winogrona', 'grejpfrut',
    'mango', 'śliwki', 'ananas', 'borówki', 'czereśnie',
  },
  // Mąki
  {
    'mąka jaglana', 'mąka gryczana', 'mąka żytnia typ 2000', 'mąka ryżowa',
    'mąka z tapioki', 'mąka amarantusowa', 'mąka orkiszowa',
    'mąka pełnoziarnista', 'mąka owsiana', 'mąka owsiana pełnoziarnista',
  },
  // Płatki
  {
    'płatki owsiane', 'płatki owsiane górskie', 'płatki jaglane',
    'płatki gryczane', 'płatki ryżowe', 'płatki orkiszowe',
  },
  // Ryż / kasze / makarony
  {
    'ryż biały', 'ryż basmati', 'ryż jaśminowy', 'ryż brązowy', 'ryż dziki',
    'komosa ryżowa', 'kasza gryczana', 'kasza jaglana', 'kasza pęczak',
    'kasza bulgur', 'kasza owsiana', 'kasza jęczmienna', 'amarantus',
    'makaron gryczany', 'makaron jaglany', 'makaron żytni', 'makaron ryżowy',
    'makaron pełnoziarnisty', 'makaron orkiszowy', 'makaron bezglutenowy',
  },
  // Ziemniaki i zamienniki (100 g ryżu/kaszy = 450–500 g ziemniaków)
  {
    'ziemniaki', 'batat', 'bataty', 'topinambur',
  },
  // Pieczywo
  {
    'chleb żytni razowy', 'chleb żytni na zakwasie', 'chleb orkiszowy',
    'chleb pełnoziarnisty', 'chleb bezglutenowy', 'bułka owsiana',
    'bułka grahamka', 'bułka pełnoziarnista',
  },
  // Pasty
  {
    'hummus', 'pasty warzywne',
  },
  // Słodzidła
  {
    'miód', 'syrop klonowy', 'syrop z agawy',
  },

  // ── Źródła białka ──────────────────────────────────────────────────────
  // Chude mięso i zamienniki
  {
    'pierś kurczaka', 'pierś indyka', 'mięso mielone z indyka',
    'mielone mięso drobiowe', 'schab wieprzowy', 'polędwiczka wieprzowa',
    'polędwica wołowa', 'rostbef wołowy', 'tofu', 'krewetki',
  },
  // Chuda ryba i owoce morza
  {
    'dorsz świeży', 'mintaj', 'pstrąg', 'morszczuk', 'sandacz',
    'tuńczyk w sosie własnym', 'krewetki',
  },
  // Tłusta ryba
  {
    'halibut', 'łosoś wędzony', 'śledź', 'makrela', 'pstrąg tęczowy',
  },
  // Strączki
  {
    'ciecierzyca konserwowa', 'soczewica', 'fasola czerwona',
    'fasola biała konserwowa', 'groch', 'soja',
  },
  // Nabiał białkowy
  {
    'serek wiejski', 'ser twarogowy półtłusty', 'tofu',
  },
  // Mleko i napoje roślinne
  {
    'mleko 1,5%', 'mleko bezlaktozowe', 'napój sojowy niesłodzony',
    'napój migdałowy niesłodzony', 'napój owsiany niesłodzony',
  },

  // ── Źródła tłuszczu ────────────────────────────────────────────────────
  // Orzechy i nasiona
  {
    'orzechy włoskie', 'orzechy nerkowca', 'orzechy laskowe',
    'orzechy pistacjowe', 'orzechy piniowe', 'orzechy pekan',
    'orzechy arachidowe', 'migdały', 'płatki migdałów', 'mieszanka orzechów',
    'siemię lniane', 'sezam', 'pestki słonecznika', 'pestki dyni',
    'wiórki kokosowe', 'masło orzechowe', 'nasiona chia',
  },
  // Tłuszcze / oleje
  {
    'oliwa', 'olej rzepakowy', 'olej z awokado', 'olej kokosowy',
    'olej sezamowy', 'masło',
  },
];

/// Wymienniki składnika [ing] (bez niego samego).
/// Suma wszystkich grup, do których należy.
Set<String> substitutesOf(String ing) {
  final n = ing.toLowerCase();
  final result = <String>{};
  for (final group in substituteGroups) {
    if (group.contains(n)) result.addAll(group);
  }
  result.remove(n);
  return result;
}
