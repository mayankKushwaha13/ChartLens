# ChartLens 🎵

**Music chart analytics powered by algorithms, graph theory, and relational databases.**

ChartLens is a Flutter application that transforms Billboard Hot 100 and Billboard 200 data (2022 - 2025) into interactive music analytics. It combines a local SQLite database, custom data processing algorithms, and artist collaboration graph analysis to explore song performance, artist rankings, album trends, and relationships within the music ecosystem.

<img width="383" height="772" alt="image" src="https://github.com/user-attachments/assets/c5edbea2-c529-4d41-873c-7b3300d243c8" />
<img width="382" height="716" alt="image" src="https://github.com/user-attachments/assets/10446558-8afb-4a56-89f2-1d88ed279546" />
<img width="382" height="782" alt="image" src="https://github.com/user-attachments/assets/06a306f6-dcb8-4cb6-8ad4-e9890ee61a88" />
<img width="383" height="785" alt="image" src="https://github.com/user-attachments/assets/b0f0a84c-ffbf-4b08-a9bf-1dc12d5bd3c0" />
<img width="376" height="782" alt="image" src="https://github.com/user-attachments/assets/2d9797eb-f192-4fd0-9073-f0822106d536" />
<img width="390" height="768" alt="image" src="https://github.com/user-attachments/assets/421e4ca1-6f6e-4cb8-b3f9-2a9d9cb0bccd" />
<img width="381" height="773" alt="image" src="https://github.com/user-attachments/assets/b1c789cc-cdcb-4a9c-9098-246fab72c411" />
<img width="387" height="765" alt="image" src="https://github.com/user-attachments/assets/47b0afaa-57ea-4581-abd5-1233e652eee4" />
<img width="387" height="767" alt="image" src="https://github.com/user-attachments/assets/eca8e695-5dae-4b23-bb31-ef75282d2cfc" />
<img width="390" height="772" alt="image" src="https://github.com/user-attachments/assets/b507a253-20ca-4ea1-9ee8-0a6e8e1a86b9" />

## ✨ Features

- **Song Analytics:** Explore song rankings, historical chart performance, peak positions, chart longevity, rank changes, and performance trends.
- **Artist Analytics:** Analyze artist rankings and chart performance using aggregated historical data.
- **Album Analytics:** Explore Billboard 200 rankings and album chart history.
- **Chart Performance Insights:** Calculate rank changes, identify biggest climbers, and analyze chart-performance metrics.
- **Top-K Selection:** Retrieve high-ranking songs using a dedicated Top-K algorithm implementation.
- **Artist Collaboration Network:** Represent artists and their collaborations as a weighted graph.
- **Graph Algorithms:** Explore collaboration networks using BFS, DFS, Dijkstra's algorithm, and Louvain community detection.
- **Music Metadata Enrichment:** Enrich chart records with artist, recording, and release metadata from MusicBrainz.
- **Local Database:** Store and query chart data through a normalized SQLite schema.

## 🧠 Algorithms & Data Structures

ChartLens incorporates algorithms into real music-analysis use cases rather than treating them as isolated demonstrations.

| Algorithm / Data Structure | Application |
| --- | --- |
| Breadth First Search (BFS) | Traverse artist collaboration networks |
| Depth First Search (DFS) | Explore graph connectivity |
| Dijkstra's Algorithm | Compute shortest paths using non-negative edge weights |
| Louvain Community Detection | Identify densely connected groups in the collaboration graph |
| Custom Min Heap | Support efficient priority based processing |
| Top K Selection | Retrieve a limited set of high ranking songs |
| Weighted Graph / Adjacency Map | Represent artist collaborations and their strengths |

## 🗄️ Database & Data Engineering

ChartLens uses SQLite for persistent local storage and SQL for retrieving and aggregating chart data.

The data layer includes:

- A relational schema for artists, songs, albums, chart metadata, and historical chart entries.
- Many-to-many relationships to represent songs with multiple artists and albums with multiple artists.
- Dedicated repositories for songs, artists, albums, chart data, and collaborations.
- Data import pipelines for JSON and CSV chart datasets.
- Database validation and artist-credit parsing.
- MusicBrainz based metadata enrichment with rate limiting and retry handling.

### Data Sources

- **Billboard Hot 100:** Weekly song rankings and historical performance data.
- **Billboard 200:** Weekly album rankings and historical performance data.
- **MusicBrainz API:** Music metadata and relationships used to enrich chart records.

The project includes historical chart datasets covering 2022–2025.

## 🛠️ Tech Stack

| Technology | Purpose |
| --- | --- |
| Flutter | Cross-platform application UI |
| Dart | Application logic and algorithm implementations |
| SQLite / SQL | Local persistence, relational data modeling, and queries |
| `sqflite` | SQLite integration in Flutter |
| `fl_chart` | Chart visualizations |
| MusicBrainz API | Music metadata enrichment |

## 🏗️ Project Structure

```text
lib/
├── algorithms/
│   ├── collaboration_graph.dart
│   ├── collaboration_graph_builder.dart
│   ├── dijkstra.dart
│   ├── graph_traversal.dart
│   ├── louvain.dart
│   ├── min_heap.dart
│   └── top_k_songs.dart
├── app/
├── database/
│   ├── artist_parser.dart
│   ├── database_helper.dart
│   ├── database_importer.dart
│   ├── database_schema.dart
│   └── database_validator.dart
├── repositories/
│   ├── album_repository.dart
│   ├── artist_repository.dart
│   ├── chart_repository.dart
│   ├── collaboration_repository.dart
│   └── song_repository.dart
├── screens/
├── services/
│   ├── analytics_service.dart
│   ├── collaboration_graph_service.dart
│   ├── musicbrainz_enricher.dart
│   └── musicbrainz_service.dart
└── main.dart

assets/
└── data/
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK compatible with the project's Flutter version
- Android Studio or another supported Flutter development environment

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/mayankKushwaha13/ChartLens.git
   cd ChartLens
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the application:

   ```bash
   flutter run
   ```

### Database Initialization

ChartLens initializes its local SQLite database through its database layer and imports chart data from the project's bundled datasets.

MusicBrainz enrichment uses its API and is subject to the service's request limits. Network access may be required for enrichment operations.

## 📊 Project Goals

ChartLens explores how algorithms and database design can turn historical music charts into useful analytical insights.

Its primary technical goals are to:

- Build a reliable data pipeline for historical chart records.
- Model music entities and their relationships in a relational database.
- Implement reusable algorithms for graph traversal, pathfinding, community detection, and ranking.
- Separate data access, analytics, algorithms, and UI into maintainable modules.
- Present the results through an interactive Flutter application.

## 🔮 Future Improvements

Potential extensions include:

- Additional graph centrality and connectivity algorithms.
- Temporal analysis of how collaboration networks change over time.
- Artist similarity and collaboration link prediction.
- Expanded chart performance comparisons and visualizations.
- Improved automated tests and algorithm benchmarking.


---

**Built with Flutter, Dart, SQLite, SQL, graph algorithms, and a passion for music analytics.**
