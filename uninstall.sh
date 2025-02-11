#!/bin/bash

CACHE_CLEAN_CONTAINER="phpserver_product-service"

repos=(
    "docker-shared"
    "auth-service"
    "user-service"
    "product-service"
    "stock-service"
    "cart-service"
    "campaign-service"
    "order-service"
)

## -----------------------------------
## 1️⃣ Belirlenen container için cache temizleme işlemi
## -----------------------------------
echo "🧹 Cache temizleniyor: $CACHE_CLEAN_CONTAINER"

if docker ps --format '{{.Names}}' | grep -q "$CACHE_CLEAN_CONTAINER"; then
    echo "🔄 $CACHE_CLEAN_CONTAINER için cache temizleniyor..."
    docker exec -it "$CACHE_CLEAN_CONTAINER" sh -c "
        cd src &&
        php artisan cache:clear &&
        php artisan config:clear &&
        php artisan route:clear &&
        php artisan view:clear
    "
    echo "✅ $CACHE_CLEAN_CONTAINER için cache temizlendi!"
else
    echo "⚠️ $CACHE_CLEAN_CONTAINER için çalışan bir PHP container bulunamadı, cache temizleme atlandı!"
fi
echo "✅ Laravel cache temizleme işlemi tamamlandı!"
echo "---------------------------------------"

## -----------------------------------
## 2️⃣ Servisleri durdur ve kaldır
## -----------------------------------
for repo in "${repos[@]}"; do
    if [ -d "$repo" ]; then
        echo "📌 $repo servisi durduruluyor..."

        cd "$repo"

        # Eğer docker-compose.yml varsa servisleri kapat
        if [ -f "docker-compose.yml" ]; then
            echo "🛑 $repo için docker-compose down çalıştırılıyor..."
            docker-compose down -v
            echo "✅ $repo servisleri durduruldu!"
        else
            echo "⚠️ $repo dizininde docker-compose.yml bulunamadı, atlanıyor! ⚠️"
        fi

        cd ..

        # Klasörü tamamen sil
        echo "🗑️ $repo dizini siliniyor..."
        rm -rf "$repo"
        echo "✅ $repo tamamen kaldırıldı!"
    else
        echo "⚠️ $repo klasörü bulunamadı, zaten kaldırılmış olabilir. ⚠️"
    fi

    echo "---------------------------------------"
done

echo "🎉 Tüm servisler durduruldu, cache temizlendi ve repolar kaldırıldı!"
