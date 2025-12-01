// Dil ayarları
const languageConfig = {
    // Desteklenen diller - Flutter ile eşleşen
    supportedLanguages: {
        'ar': "Arabic",
        'bn': "Bengali", 
        'de': "German",
        'en': "English",
        'es': "Spanish",
        'fr': "French",
        'hi': "Hindi",
        'id': "Indonesian",
        'ja': "Japanese",
        'ku': "Kurmanci",
        'pt': "Portuguese",
        'ru': "Russian",
        'sw': "Swahili",
        'tr': "Turkish",
        'ur': "Urdu",
        'za': "Zazakî",
        'zh': "Chinese"
    },
    
    // Varsayılan dil
    defaultLanguage: 'en',
    
    // Mevcut dil (URL parametresinden veya cihaz dilinden alınacak)
    current: 'en',
    
    // Dil değiştirme fonksiyonu
    setLanguage: function(langCode) {
        // Özel eşleştirmeler
        if (langCode === 'zh-cn' || langCode === 'zh_hans' || langCode === 'zh_tw') {
            langCode = 'zh';
        } else if (langCode === 'pt-br' || langCode === 'pt_br') {
            langCode = 'pt';
        }
        
        if (this.supportedLanguages[langCode]) {
            this.current = langCode;
            console.log('WebView dil değiştirildi:', langCode);
            
            // URL'den dil parametresini güncelle
            this.updateUrlLanguageParam(langCode);
            
            // UI'yı güncelle
            if (typeof updateUIText === 'function') {
                updateUIText();
            }
            return true;
        }
        return false;
    },
    
    // URL'den dil parametresini al
    getLanguageFromUrl: function() {
        const urlParams = new URLSearchParams(window.location.search);
        let langParam = urlParams.get('lang');
        
        if (langParam) {
            // Dil kodunu temizle
            langParam = langParam.toLowerCase().trim();
            
            // Özel eşleştirmeler
            if (langParam === 'zh-cn' || langParam === 'zh_hans' || langParam === 'zh_tw') {
                return 'zh';
            } else if (langParam === 'pt-br' || langParam === 'pt_br') {
                return 'pt';
            }
            
            // Desteklenen dillerden mi kontrol et
            if (this.supportedLanguages[langParam]) {
                return langParam;
            }
        }
        
        return null;
    },
    
    // URL'deki dil parametresini güncelle
    updateUrlLanguageParam: function(langCode) {
        const url = new URL(window.location.href);
        url.searchParams.set('lang', langCode);
        window.history.replaceState({}, '', url.toString());
    },
    
    // Dil algıla ve ayarla
    detectAndSetLanguage: function() {
        // Önce URL'den dene
        const urlLang = this.getLanguageFromUrl();
        if (urlLang) {
            this.current = urlLang;
            console.log('URL\'den dil algılandı:', urlLang);
            return;
        }
        
        // Sonra cihaz dilinden dene
        const browserLang = navigator.language || navigator.userLanguage;
        let detectedLang = browserLang.split('-')[0].toLowerCase();
        
        // Özel eşleştirmeler
        if (detectedLang === 'zh') {
            detectedLang = 'zh';
        }
        
        if (this.supportedLanguages[detectedLang]) {
            this.current = detectedLang;
            console.log('Tarayıcı dilinden algılandı:', detectedLang);
        } else {
            this.current = this.defaultLanguage;
            console.log('Varsayılan dil kullanılıyor:', this.defaultLanguage);
        }
    },
    
    // Mevcut dili al
    getCurrent: function() {
        return this.current;
    },
    
    // Tüm dilleri al
    getAvailableLanguages: function() {
        return this.supportedLanguages;
    },
    
    // Dil adını al
    getLanguageName: function(code) {
        return this.supportedLanguages[code] || code.toUpperCase();
    }
};

// Sayfa yüklendiğinde dil algıla
document.addEventListener('DOMContentLoaded', function() {
    languageConfig.detectAndSetLanguage();
    
    if (typeof updateUIText === 'function') {
        updateUIText();
    }
});

// Dil değişimi için global fonksiyon
function changeLanguage(langCode) {
    if (languageConfig.setLanguage(langCode)) {
        console.log('Dil değiştirildi:', langCode);
    }
}

// Flutter'dan gelen dil değişiklikleri için
if (window.flutter_inappwebview) {
    // Flutter'dan mesaj almak için
    window.addEventListener('flutterInAppWebViewPlatformReady', function(event) {
        console.log('Flutter WebView hazır');
    });
}

// Dil değişikliklerini dinlemek için
window.addEventListener('languageChanged', function(event) {
    if (event.detail && event.detail.langCode) {
        changeLanguage(event.detail.langCode);
    }
});
