# Power Query — Drinking Water For All

![DWFA banner](../assets/images/dwfa_banner.png)

Ce dossier contient les **25 requêtes M** de préparation du projet DWFA.

## Préparer les sources

- `data/raw/` : six CSV métier et le dictionnaire des données source.
- `data/reference/CountryGeography.csv` : copie du référentiel géographique conservée pour la traçabilité du projet.
- `data/external/` : extractions JSON OMS, archive ZIP FAO et manifeste de provenance des sources.

Configurer `pDataFolder` pour le dossier `data/raw` et `pExternalFolder` pour `data/external`. Conserver `pExternalSourceMode = "Fichiers bruts"` pour reproduire ce lot sans CSV intermédiaire ni Python. Les fonctions Power Query lisent et préparent directement les extractions OMS/FAO fournies.

Le mode optionnel `CSV fourni` exige le fichier préparé `data/raw/ExternalContextCountryYear.csv`

## Créer les requêtes

Les fichiers `.pq` contiennent du langage M. Pour chaque requête, utiliser **Transformer les données > Nouvelle source > Requête vide**, renommer la requête avec le nom indiqué dans son en-tête, puis coller le fichier complet dans l’**Éditeur avancé**.

Créer toutes les requêtes avant l’actualisation. Les noms doivent rester identiques, car les requêtes se référencent entre elles. Les numéros des fichiers organisent le pack ; une requête peut référencer un fichier de numéro plus élevé.

| Fichier | Requête | Chargement | Objectif |
|---|---|---|---|
| [00_pDataFolder.pq](00_pDataFolder.pq) | `pDataFolder` | Désactivé | Dossier local contenant les CSV, dont CountryGeography.csv |
| [01_fxReadCsv.pq](01_fxReadCsv.pq) | `fxReadCsv` | Désactivé | Lecture UTF-8 commune de tous les fichiers |
| [02_fxNormalizeCountry.pq](02_fxNormalizeCountry.pq) | `fxNormalizeCountry` | Désactivé | Harmoniser les noms de pays sans rapprochement approximatif |
| [03_fxAssertUnique.pq](03_fxAssertUnique.pq) | `fxAssertUnique` | Désactivé | Bloquer une jointure multiplicative au lieu de supprimer arbitrairement les doublons |
| [04_fxPercent.pq](04_fxPercent.pq) | `fxPercent` | Désactivé | Convertir un taux source 0–100 en fraction 0–1 avec contrôle |
| [05_stg_RegionCountry.pq](05_stg_RegionCountry.pq) | `stg_RegionCountry` | Désactivé | Une ligne par pays avec sa région OMS |
| [06_stg_CountryGeography.pq](06_stg_CountryGeography.pq) | `stg_CountryGeography` | Désactivé | Référentiel manuel de continents et codes ISO3 auditable |
| [07_stg_Population.pq](07_stg_Population.pq) | `stg_Population` | Désactivé | Population en personnes, une ligne par pays année et milieu |
| [08_stg_Water.pq](08_stg_Water.pq) | `stg_Water` | Désactivé | Accès à au moins un service basique et service géré en toute sécurité |
| [09_stg_Mortality.pq](09_stg_Mortality.pq) | `stg_Mortality` | Désactivé | 183 pays en 2016 ; taux pour 100 000 et décès WASH estimés |
| [10_stg_Stability.pq](10_stg_Stability.pq) | `stg_Stability` | Désactivé | Stabilité politique ; 2001 absent ; pas de remplacement par zéro |
| [11_Dim_Country.pq](11_Dim_Country.pq) | `Dim_Country` | Activé | 194 pays ; dimension du schéma en étoile |
| [12_Dim_Year.pq](12_Dim_Year.pq) | `Dim_Year` | Activé | Une ligne par année ; données annuelles, sans calendrier quotidien artificiel |
| [13_Fact_CountryYear.pq](13_Fact_CountryYear.pq) | `Fact_CountryYear` | Activé | Une ligne par pays année ; 3 686 lignes ; table de faits unique |
| [14_QA_MissingData.pq](14_QA_MissingData.pq) | `QA_MissingData` | Désactivé | Contrôle des données disponibles par année, sans ajouter de table au modèle |
| [15_Param_Stability.pq](15_Param_Stability.pq) | `Param_Stability` | Activé | Seuil minimal de stabilité modifiable par segment ; table déconnectée |
| [16_Param_StabilityMode.pq](16_Param_StabilityMode.pq) | `Param_StabilityMode` | Activé | Activer ou désactiver le seuil ; inconnus exclus seulement en mode actif |
| [17_stg_ExternalContext.pq](17_stg_ExternalContext.pq) | `stg_ExternalContext` | Désactivé | Choisir la préparation des compléments : CSV fourni, fichiers bruts ou sources en ligne |
| [18_pExternalSourceMode.pq](18_pExternalSourceMode.pq) | `pExternalSourceMode` | Désactivé | Sélectionner le mode de lecture des compléments OMS et FAO |
| [19_pExternalFolder.pq](19_pExternalFolder.pq) | `pExternalFolder` | Désactivé | Définir le dossier local contenant les extractions brutes OMS et FAO |
| [20_fxReadZipCsv.pq](20_fxReadZipCsv.pq) | `fxReadZipCsv` | Désactivé | Lire un CSV dans une archive ZIP Store ou Deflate, sans extraction manuelle |
| [21_src_OMSContext.pq](21_src_OMSContext.pq) | `src_OMSContext` | Désactivé | Préparer les totaux nationaux d’assainissement et d’hygiène depuis les JSON OMS ou leur API |
| [22_src_FAOLand.pq](22_src_FAOLand.pq) | `src_FAOLand` | Désactivé | Préparer la superficie terrestre depuis le ZIP FAOSTAT et convertir les milliers d’hectares en km² |
| [23_stg_ExternalContextFromSources.pq](23_stg_ExternalContextFromSources.pq) | `stg_ExternalContextFromSources` | Désactivé | Assembler les sources OMS et FAO sur la grille des pays et des années du modèle |
| [24_fxLatestExternalFile.pq](24_fxLatestExternalFile.pq) | `fxLatestExternalFile` | Désactivé | Repérer le fichier brut le plus récent par date de modification, puis par nom |

Les fonctions, paramètres, tables de préparation et `QA_MissingData` restent sans chargement dans le modèle. Charger uniquement `Dim_Country`, `Dim_Year`, `Fact_CountryYear`, `Param_Stability` et `Param_StabilityMode`.

## Modèle et règles de préparation

`Fact_CountryYear` conserve une ligne par pays et année : 3 686 lignes dans le périmètre fourni. Les clés sont vérifiées avant et après les jointures. Les pourcentages sont convertis en fractions entre 0 et 1 ; la superficie FAO en milliers d’hectares est convertie en km² par multiplication par 10.

Les valeurs manquantes restent manquantes. Les régions OMS et les continents sont conservés comme deux découpages distincts. Les fonctions de lecture des sources externes contrôlent les clés et les correspondances géographiques.

Après **Fermer et appliquer**, vérifier les deux relations actives à sens unique :

- `Dim_Country[Country]` (1) → `Fact_CountryYear[Country]` (*) ;
- `Dim_Year[Year]` (1) → `Fact_CountryYear[Year]` (*).

Les tables de paramètres restent déconnectées. Power Query prépare les données ; les relations appartiennent au modèle Power BI.

## Références

- [Power Query M](https://learn.microsoft.com/en-us/powerquery-m/)
- [Modèle en étoile Power BI](https://learn.microsoft.com/en-us/power-bi/guidance/star-schema)