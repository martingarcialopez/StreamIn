# App Store listing

What goes into App Store Connect for StreamIn 1.0, English and Spanish side by side. The privacy
answers match `StreamIn/Resources/PrivacyInfo.xcprivacy` and the
[privacy policy](https://martingarcialopez.github.io/StreamIn/privacy/). Counts are characters as
App Store Connect counts them; regenerate the table after any edit.

## Product page

| Field | Limit | English | # | Spanish | # |
|---|---:|---|---:|---|---:|
| Name | 30 | StreamIn: Where to Watch | 24 | StreamIn: Dónde verla | 21 |
| Subtitle | 30 | Your services, home and abroad | 30 | Tus servicios, aquí y fuera | 27 |
| Promotional text | 170 | Search a movie and see at once whether you can watch it tonight: on your services, free where you are, or on your services in other countries. | 142 | Busca una película y descubre al instante si puedes verla esta noche: en tus servicios, gratis donde estás o con tus servicios en otros países. | 143 |
| Keywords | 100 | movies,film,streaming,guide,watchlist,availability,subscriptions,catalog,cinema,finder,travel,free | 98 | películas,cine,streaming,guía,catálogo,plataformas,suscripción,watchlist,gratis,viajes,buscador | 95 |
| Description | 4000 | [below](#description) | 1280 | [below](#description) | 1383 |
| What's new | 4000 | [below](#whats-new-in-this-version) | 150 | [below](#whats-new-in-this-version) | 161 |

**Keywords** repeat no word of the name or subtitle (App Store search already indexes those) and
name no streaming service: other companies' trademarks in keywords are a common rejection.

### Description

<table>
<tr><th width="50%">English</th><th width="50%">Spanish</th></tr>
<tr><td valign="top">

Can I watch it tonight? StreamIn answers at a glance.

Search a movie and StreamIn shows where it streams in your country: on the services you pay for, or on a free one. Open it and you get one clear verdict:

🍿 Watch now: one of your services, or a free one, has it where you are.
🌍 On your services abroad: not at home, but your services carry it in other countries, with a spinning globe and the flags of every country that has it.
📖 Go read a book: it's not on your services, here or abroad.

FEATURES
• Pick the services you pay for once. StreamIn recognizes them in every country, even when a service has more than one plan.
• Search results show each movie's services as they arrive, row by row.
• Save movies to your watchlist with the heart. Saved movies open complete, even offline.
• Choose your region and your language: English or Spanish, for the app and the movie information.
• Made for iPhone and iPad, in light and dark mode.

PRIVATE BY DESIGN
No account, no ads, no tracking. Your services, region and watchlist stay on your device.

CREDITS
Movie data from The Movie Database (TMDB). Streaming availability from JustWatch. StreamIn uses the TMDB API but is not endorsed or certified by TMDB, and is not affiliated with JustWatch or with any streaming service.

</td><td valign="top">

¿Puedo verla esta noche? StreamIn te lo dice de un vistazo.

Busca una película y StreamIn te muestra dónde se puede ver en tu país: en los servicios que pagas o en uno gratuito. Ábrela y tendrás un veredicto claro:

🍿 Ya puedes verla: uno de tus servicios, o uno gratuito, la tiene donde estás.
🌍 Con tus servicios en el extranjero: aquí no está, pero tus servicios la tienen en otros países, con un globo que gira y las banderas de todos los países donde está.
📖 Toca leer un libro: no está en tus servicios, ni aquí ni fuera.

FUNCIONES
• Elige una vez los servicios que pagas. StreamIn los reconoce en cada país, aunque un servicio tenga más de un plan.
• Los resultados de búsqueda muestran los servicios de cada película a medida que llegan, fila a fila.
• Guarda películas en tu watchlist con el corazón. Se abren completas, incluso sin conexión.
• Elige tu región y tu idioma: inglés o español, para la app y para la información de las películas.
• Hecha para iPhone y iPad, en modo claro y oscuro.

PRIVADA POR DISEÑO
Sin cuentas, sin anuncios, sin rastreo. Tus servicios, tu región y tu watchlist se quedan en tu dispositivo.

CRÉDITOS
Datos de películas de The Movie Database (TMDB). Disponibilidad en streaming de JustWatch. StreamIn usa la API de TMDB, pero TMDB no respalda ni certifica esta app, que tampoco está afiliada a JustWatch ni a ningún servicio de streaming.

</td></tr>
</table>

### What's new in this version

App Store Connect doesn't show this field for a first version, so this text may never appear;
1.1 replaces it with its own notes.

| English | Spanish |
|---|---|
| The first version of StreamIn: search a movie, see where to watch it at home or on your services abroad, and keep a watchlist. In English and Spanish. | La primera versión de StreamIn: busca una película, descubre dónde verla aquí o con tus servicios en el extranjero y guarda tu watchlist. En inglés y en español. |

## App information

| Field | Value |
|---|---|
| Primary category | Entertainment |
| Secondary category | Utilities. StreamIn is a lookup tool people open before they watch, not something they watch in; Utilities is a smaller list than Entertainment, and it fits the "check before you watch" use. |
| Copyright | 2026 Martín García (App Store Connect adds the ©) |
| Support URL | https://martingarcialopez.github.io/StreamIn/support/ (es: …/StreamIn/es/support/) |
| Privacy Policy URL | https://martingarcialopez.github.io/StreamIn/privacy/ (es: …/StreamIn/es/privacy/) |
| Marketing URL | None |

## Age rating

Proposed answers; App Store Connect computes the rating from them. Expected result: **13+**, like
other movie-information apps. Movies come from TMDB with `include_adult=false`, which keeps out
adult titles, but StreamIn shows posters, titles and synopses of any other film, including horror
and R-rated ones. StreamIn makes none of this content itself.

| Question | Answer | Why |
|---|---|---|
| Profanity or crude humor | Infrequent/Mild | Some titles and synopses contain it |
| Horror/fear themes | Infrequent/Mild | Posters and synopses of horror films |
| Alcohol, tobacco or drug use or references | Infrequent/Mild | Mentioned in some synopses |
| Mature or suggestive themes | Infrequent/Mild | Synopses of dramas and thrillers |
| Sexual content or nudity | Infrequent/Mild | Some posters are suggestive; adult titles are excluded |
| Graphic sexual content and nudity | None | `include_adult=false` |
| Cartoon or fantasy violence | Infrequent/Mild | Posters and synopses of action and animated films |
| Realistic violence | Infrequent/Mild | Posters and synopses of war and crime films |
| Prolonged graphic or sadistic realistic violence | None | Text and still posters only, no video |
| Guns or other weapons | Infrequent/Mild | Shown on some posters |
| Medical or treatment information | None | |
| Simulated gambling, gambling, contests | None | |
| Unrestricted web access | No | No web views or in-app browser; the app shows only TMDB data |
| User-generated content | No | Users can't post, review or share anything |
| Messaging and chat | No | |
| Advertising | No | |
| Parental controls, age assurance | No | No accounts and nothing to restrict |

## App Privacy

**Data collected: Search History only.** The titles a user searches for are sent to TMDB, a third
party. Apple counts data sent to a third-party server as collected even when the developer never
receives it, so it is declared. A later version will also keep recent searches on the device; that
stays on the device and changes nothing here as long as TMDB remains the only recipient.

| Question | Answer |
|---|---|
| Data type | Search History |
| Linked to the user's identity | No (no accounts; requests carry no user, device or advertising identifier) |
| Used for tracking | No |
| Purpose | App Functionality (answering the search) |

Everything else is **Not Collected**. StreamIn has no accounts, analytics, ads or crash reporting.
Region, language, services and the watchlist are stored only on the device (`UserDefaults` and
SwiftData, no iCloud); region and language travel with each TMDB request but are not a collected
data type of their own here (they are not location, and identify no one). This matches the privacy
manifest: `NSPrivacyTracking` false, `NSPrivacyCollectedDataTypeSearchHistory` (not linked, not
tracking, app functionality), and `UserDefaults` declared with reason `CA92.1` (the app's own
settings).

**Export compliance:** the only encryption is the system's HTTPS, which is exempt;
`ITSAppUsesNonExemptEncryption = NO` is in the app's Info.plist, so App Store Connect doesn't ask.

## Review notes

App Review notes are a single field, in English. The three titles were checked against TMDB on
Oct 30, 2026, for the United States with the three services below, using the app's verdict rules.
Each is a studio's own release (Netflix, Apple) or a long-standing deal, so they should hold, but
**re-check them in the app the week of submission**: availability changes daily.

> StreamIn needs no account or login; everything works right away.
>
> Data: movie information and streaming availability come from the public TMDB API
> (api.themoviedb.org); TMDB's availability data is provided by JustWatch. The app sends no user or
> device identifiers. The only data that leaves the device is the title searched for, sent to TMDB
> and declared as Search History (not linked to the user, not used for tracking).
>
> On first launch, a welcome screen asks for the streaming services you pay for. For the examples
> below, pick Netflix, Amazon Prime Video and Disney Plus, then tap Done. The region follows the device's
> region (United States for these examples); it can be changed in Settings, the gear on the Search
> or Watchlist tab.
>
> Each movie's page leads with one verdict. To see each one, search and open:
> 1. "Watch now" (one of your services, or a free one, has it in your region): Glass Onion: A
>    Knives Out Mystery (2022), on Netflix.
> 2. "On your services abroad" (not in your region, but your services carry it in other
>    countries; tap a service row to see every country): Spirited Away (2002), on Netflix outside
>    the United States.
> 3. "Go read a book" (not on your services, here or abroad): Greyhound (2020), an Apple TV
>    original.
>
> The Watchlist tab lists movies saved with the heart on a movie's page.
