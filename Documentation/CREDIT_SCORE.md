# Credit Score V1

Credit Score is a new local-first feature, separate from the M57 redesign. Users manually enter and update their latest score for Experian, Equifax, or TransUnion. More owns entry and editing; Dashboard displays saved scores with their provider and scale. There is no bureau connection, account sign-in, network request, score calculation, recommendation, or combined score.

## Score identity and scale

Each provider has one latest saved score. A score stores its provider, value, scale version, last updated date, and manual source. The scale is stored with the value so a later change in a bureau's scoring system cannot silently reinterpret saved data. V1 accepts Experian 0–999 or 0–1250, Equifax 0–1000, and TransUnion 0–710 or 0–999. These ranges reflect the UK providers' published ranges as of September 2026: [Experian](https://www.experian.co.uk/consumer/1250-score.html), [Equifax](https://equifax.co.uk/products/credit/credit-score), [TransUnion](https://www.transunion.co.uk/consumer/new-credit-score). The old Experian and TransUnion scales remain selectable while their new scales roll out. The application does not infer a credit rating band or compare scores across providers.

## Architecture and migration

The domain `CreditScore` value validates provider, scale, and range without SwiftUI or SwiftData. `CreditScoreRepository` is the feature's persistence boundary. The SwiftData adapter stores one record per provider and updates that record on manual entry. Future bureau ingestion can use this boundary and add a source case without changing the views' ownership of business rules. No ingestion or networking exists in V1.

Adding the credit score record changes the persistent schema. `CairnSchemaV1` remains intact for existing stores. `CairnSchemaV2` includes the unchanged V1 model types plus the new credit score record, with a lightweight V1-to-V2 migration. The app opens V2 and must never reset an existing local store to recover from migration failure.

## Presentation

More keeps its existing destinations and adds Credit Score. The Credit Score screen lists all three providers in fixed order, showing Add score or the latest manually entered value with its scale and update date. Dashboard shows saved providers without fabricating a score when none exists. All values and states are textual, use Cairn semantic colors, and support Dynamic Type and VoiceOver.
