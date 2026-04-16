#include <WiFi.h>
#include <HTTPClient.h>
#include <SPI.h>
#include <MFRC522.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>

namespace Config {
    const char* SSID = "ALHN-76A5";
    const char* PASSWORD = "T5eJdezqc5";
    
    const char* ENDPOINT = "";
    const char* PROJECT_ID = "";
    const char* API_KEY = "";

    constexpr int SS_PIN = 5;
    constexpr int RST_PIN = 22;
}

class VaultAuthenticator {
private:
    MFRC522 rfid;
    WiFiClientSecure secureClient;

public:
    VaultAuthenticator() : rfid(Config::SS_PIN, Config::RST_PIN) {
        secureClient.setInsecure();
    }

    void begin() {
        SPI.begin();
        rfid.PCD_Init();
        Serial.println(F("[SYSTEM] UniVault Security Core Initialized."));
    }

    bool isCardPresent() {
        return (rfid.PICC_IsNewCardPresent() && rfid.PICC_ReadCardSerial());
    }

    String getCardUID() {
        String uid = "";
        for (byte i = 0; i < rfid.uid.size; i++) {
            uid += (rfid.uid.uidByte[i] < 0x10 ? "0" : "");
            uid += String(rfid.uid.uidByte[i], HEX);
        }
        uid.toUpperCase();
        return uid;
    }

    void syncWithCloud(String uid) {
        if (WiFi.status() != WL_CONNECTED) {
            Serial.println(F("[ERROR] WiFi Disconnected. Sync Aborted."));
            return;
        }

        HTTPClient http;
        
        Serial.println(F("[CLOUD] Fetching security state..."));
        http.begin(secureClient, Config::ENDPOINT);
        http.addHeader("X-Appwrite-Project", Config::PROJECT_ID);
        http.addHeader("X-Appwrite-Key", Config::API_KEY);

        int httpCode = http.GET();
        bool isCurrentlyActive = false;

        if (httpCode == HTTP_CODE_OK) {
            String payload = http.getString();
            isCurrentlyActive = (payload.indexOf("\"is_active\":true") != -1);
            Serial.printf("[STATUS] Current Vault State: %s\n", isCurrentlyActive ? "OPEN" : "LOCKED");
        } else {
            Serial.printf("[ERROR] GET Request failed, code: %d\n", httpCode);
            http.end();
            return;
        }
        http.end();

        bool nextState = !isCurrentlyActive;
        Serial.println(F("[CLOUD] Synchronizing new state..."));
        
        http.begin(secureClient, Config::ENDPOINT);
        http.addHeader("Content-Type", "application/json");
        http.addHeader("X-Appwrite-Project", Config::PROJECT_ID);
        http.addHeader("X-Appwrite-Key", Config::API_KEY);

        String jsonBody = "{\"data\": {\"is_active\": " + String(nextState ? "true" : "false") + 
                          ", \"current_uid\": \"" + uid + "\"}}";

        int patchCode = http.PATCH(jsonBody);

        if (patchCode == HTTP_CODE_OK || patchCode == 204) {
            Serial.printf("[SUCCESS] Vault %s\n", nextState ? "UNLOCKED" : "SECURED");
        } else {
            Serial.printf("[ERROR] PATCH failed, code: %d\n", patchCode);
        }
        
        http.end();
    }

    void halt() {
        rfid.PICC_HaltA();
        rfid.PCD_StopCrypto1();
    }
};

VaultAuthenticator vault;

void setup() {
    Serial.begin(115200);
    
    WiFi.begin(Config::SS_PIN == 5 ? Config::SS_PIN : Config::SS_PIN, Config::PASSWORD);
    WiFi.begin(Config::SSID, Config::PASSWORD);
    
    Serial.print(F("[WIFI] Connecting"));
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println(F("\n[WIFI] Connected. Network Layer Active."));

    vault.begin();
}

void loop() {
    if (vault.isCardPresent()) {
        String tappedUID = vault.getCardUID();
        Serial.printf("\n[EVENT] Authentication Token Detected: %s\n", tappedUID.c_str());
        
        vault.syncWithCloud(tappedUID);
        vault.halt();
        
        Serial.println(F("[SYSTEM] Ready for next input."));
        delay(3000);
    }
}