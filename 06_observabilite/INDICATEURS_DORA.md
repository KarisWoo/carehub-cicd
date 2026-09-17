# Indicateurs DORA - CareHub

## 1. Fréquence de déploiement
**Définition :** nombre de déploiements de production réussis sur une période.

**Calcul :**
`Nombre de déploiements production réussis / nombre de jours observés`

Exemple de tableau à compléter avec vos exécutions réelles :

| Date | Commit | Workflow | Statut | Environnement |
|---|---|---|---|---|
| A COMPLETER | A COMPLETER | CareHub CI-CD | success/failure | production |

## 2. Lead Time for Changes
**Définition :** délai entre le commit et son déploiement réussi en production.

**Calcul :**
`heure du déploiement réussi - heure du commit`

| Commit | Heure commit | Heure déploiement | Lead time |
|---|---|---|---|
| A COMPLETER | A COMPLETER | A COMPLETER | A CALCULER |

## 3. Change Failure Rate (optionnel)
`déploiements provoquant incident ou rollback / nombre total de déploiements x 100`

## 4. Mean Time to Restore (optionnel)
`temps total de restauration après incidents / nombre d'incidents`

> Les valeurs doivent venir de vos exécutions GitHub Actions/VPS. Ne pas inventer de chiffres.
