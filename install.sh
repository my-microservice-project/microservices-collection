#!/bin/bash
repos=(
    "docker-shared"
    "auth-service"
    "user-service"
    "product-service"
    "stock-service"
    "cart-service"
)

for repo in "${repos[@]}"; do
    echo "⏳ $repo klonlanıyor..."
    git clone "https://github.com/my-microservice-project/$repo.git"

    # Eğer klonlama başarılı olduysa işlem yap
    if [ -d "$repo" ]; then
        echo "✅ $repo klonlandı. .env.example kontrol ediliyor..."
        cd "$repo"

        # Ana dizindeki .env.example dosyasını kopyala
        if [ -f ".env.example" ]; then
            cp .env.example .env
            echo "🔄 Ana dizindeki .env.example → .env olarak kopyalandı ✅"
        else
            echo "⚠️ Ana dizinde .env.example dosyası bulunamadı! ⚠️"
        fi

        # Eğer src dizini varsa içine gir ve .env.example'ı kopyala
        if [ -d "src" ]; then
            echo "📂 src dizini bulundu, içine giriliyor..."
            cd src

            if [ -f ".env.example" ]; then
                cp .env.example .env
                echo "🔄 src/.env.example → src/.env olarak kopyalandı ✅"
            else
                echo "⚠️ src dizininde .env.example dosyası bulunamadı! ⚠️"
            fi

            # Eğer composer.json src/ içinde ise, burada çalıştır
            if [ -f "composer.json" ]; then
                echo "🚀 src/ dizininde composer install çalıştırılıyor..."
                composer install --no-interaction --optimize-autoloader
                echo "✅ src/ dizininde composer install tamamlandı!"
            fi

            cd ..
        else
            echo "⚠️ src dizini bulunamadı, atlanıyor... ⚠️"
        fi

        # Eğer composer.json ana dizinde varsa burada çalıştır
        if [ -f "composer.json" ]; then
            echo "🚀 Ana dizinde composer install çalıştırılıyor..."
            composer install --no-interaction --optimize-autoloader
            echo "✅ Ana dizinde composer install tamamlandı!"
        fi

        cd ..
    else
        echo "🚨 $repo klasörü bulunamadı, klonlama başarısız olmuş olabilir! 🚨"
    fi

    echo "---------------------------------------"
done

echo "🎉 Tüm repolar indirildi, .env dosyaları oluşturuldu ve composer bağımlılıkları yüklendi!"