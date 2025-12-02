import random
import json

class OSINTEnricher:
    def __init__(self):
        self.threat_feeds = [
            "PCC_KNOWN_IPS",
            "CV_CRYPTO_WALLETS",
            "DARKWEB_LEAKS"
        ]

    def enrich_entity(self, entity_type, value):
        """
        Simulates querying Shodan, VirusTotal, and DarkWeb leaks.
        """
        risk_score = random.uniform(0, 1)
        
        return {
            "entity": value,
            "type": entity_type,
            "risk_score": risk_score,
            "known_affiliations": [random.choice(self.threat_feeds)] if risk_score > 0.7 else [],
            "leaked_creds": risk_score > 0.8,
            "geo_location": "Sao Paulo, BR" if risk_score > 0.5 else "Unknown"
        }

if __name__ == "__main__":
    enricher = OSINTEnricher()
    print(json.dumps(enricher.enrich_entity("IP", "200.100.50.25"), indent=2))
