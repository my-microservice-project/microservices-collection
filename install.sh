#!/bin/bash

# Shell'in Bash olduğundan emin ol
if [ -z "$BASH_VERSION" ]; then
    echo "⚠️ Bu script yalnızca Bash kabuğunda çalıştırılmalıdır!"
    exit 1
fi

# **Migrate çalıştırılacak servisler**
migrate_services=(
    "user-service"
    "product-service"
    "stock-service"
    "campaign-service"
    "order-service"
)

# Repo listesi
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
## 1️⃣ Tüm repoları indir
## -----------------------------------
echo "📥 Tüm repolar indiriliyor..."
for repo in "${repos[@]}"; do
    echo "⏳ $repo indiriliyor..."

    if [ -d "$repo" ]; then
        echo "🗑️  $repo klasörü zaten mevcut, siliniyor..."
        sudo rm -rf "$repo"
    fi

    git clone "https://github.com/my-microservice-project/$repo.git"

    if [ ! -d "$repo" ]; then
        echo "🚨 $repo klasörü bulunamadı, klonlama başarısız olmuş olabilir! 🚨"
    else
        echo "✅ $repo indirildi."
    fi
    echo "---------------------------------------"
done

## -----------------------------------
## 2️⃣ .env işlemlerini yap
## -----------------------------------
echo "🔄 .env dosyaları oluşturuluyor..."
for repo in "${repos[@]}"; do
    if [ -d "$repo" ]; then
        echo "🔄 $repo için .env ayarlanıyor..."
        cd "$repo" || exit 1

        [ -f ".env.example" ] && cp .env.example .env && echo "✅ .env oluşturuldu!" || echo "⚠️ .env.example bulunamadı!"

        if [ -d "src" ]; then
            cd src || exit 1
            [ -f ".env.example" ] && cp .env.example .env && echo "✅ src/.env oluşturuldu!" || echo "⚠️ src/.env.example bulunamadı!"
            cd ..
        fi

        cd ..
    fi
done
echo "✅ Tüm .env işlemleri tamamlandı!"
echo "---------------------------------------"

## -----------------------------------
## 3️⃣ Tüm repolar için Docker Compose çalıştır
## -----------------------------------
echo "🐳 Tüm servisler başlatılıyor..."
for repo in "${repos[@]}"; do
    if [ -d "$repo" ]; then
        echo "🚀 $repo için docker-compose up -d --build çalıştırılıyor..."
        cd "$repo" || exit 1
        docker-compose up -d --build
        cd ..
    fi
done
echo "✅ Tüm servisler başlatıldı!"
echo "---------------------------------------"

## -----------------------------------
## 4️⃣ Container'ların başlamasını bekle
## -----------------------------------
echo "⏳ Servislerin tamamen başlaması bekleniyor..."
for repo in "${repos[@]}"; do
    container_name="phpserver_${repo//-/_}"

    if [[ "$repo" == "docker-shared" ]]; then
        echo "⚠️ $repo için container yok, atlanıyor."
        continue
    fi

    echo "⏳ $container_name başlatılıyor..."
    timeout=30
    elapsed=0

    while ! docker ps --format '{{.Names}}' | grep -q "$container_name"; do
        echo "🔄 Bekleniyor... ($container_name) ($elapsed saniye geçti)"
        sleep 3
        elapsed=$((elapsed + 3))

        if [ "$elapsed" -ge "$timeout" ]; then
            echo "🚨 $container_name 30 saniye içinde başlamadı, atlanıyor!"
            break
        fi
    done

    if docker ps --format '{{.Names}}' | grep -q "$container_name"; then
        echo "✅ $container_name çalışıyor!"
    fi
done
echo "✅ Tüm container'lar çalışıyor!"
echo "---------------------------------------"

## -----------------------------------
## 5️⃣ Composer işlemlerini çalıştır
## -----------------------------------
echo "📦 Composer install çalıştırılıyor..."
for repo in "${repos[@]}"; do
    container_name="phpserver_${repo//-/_}"

    if [[ "$repo" == "docker-shared" ]]; then
        continue
    fi

    if docker ps --format '{{.Names}}' | grep -q "$container_name"; then
        echo "📦 $repo içinde composer install çalıştırılıyor..."
        docker exec -it "$container_name" sh -c "
            cd src &&
            composer install --no-interaction --optimize-autoloader
        "
        echo "✅ $repo içinde composer install tamamlandı!"
    else
        echo "⚠️ $repo için container çalışmıyor, composer install atlandı!"
    fi
done
echo "✅ Tüm composer işlemleri tamamlandı!"
echo "---------------------------------------"

## -----------------------------------
## 6️⃣ **Migrate çalıştırılacak servisleri yeniden başlat**
## -----------------------------------
echo "🛑 Migration işlemi için servisler yeniden başlatılıyor..."
for repo in "${migrate_services[@]}"; do
    if [ -d "$repo" ]; then
        echo "🛑 $repo için docker-compose down -v çalıştırılıyor..."
        cd "$repo" || exit 1
        docker-compose down -v
        sleep 3  # Servisin tamamen durmasını bekle
        echo "🚀 $repo için docker-compose up -d --build çalıştırılıyor..."
        docker-compose up -d --build
        sleep 10  # Servisin tam başlamasını bekle
        cd ..
    fi
done
echo "✅ Migration işlemi için servisler yeniden başlatıldı!"
echo "---------------------------------------"

## -----------------------------------
## 7️⃣ Migration işlemleri çalıştır
## -----------------------------------
echo "🔄 Migration işlemleri başlatılıyor..."
for repo in "${migrate_services[@]}"; do
    container_name="phpserver_${repo//-/_}"

    if docker ps --format '{{.Names}}' | grep -q "$container_name"; then
        echo "⏳ $repo için migrate işlemi başlatılıyor..."
        docker exec -it "$container_name" sh -c "
            cd src &&
            php artisan migrate:fresh --seed
        "
        echo "✅ $repo için migrate işlemi tamamlandı!"
    else
        echo "⚠️ $repo için container çalışmıyor, migrate işlemi atlandı!"
    fi
done
echo "✅ Tüm migrate işlemleri tamamlandı!"
echo "---------------------------------------"

## ✅ **Tamamlandı**
echo "🎉 Tüm işlemler başarıyla tamamlandı!"
