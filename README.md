## Тестовое задание Серафимова Сергея часть первая.

### Минималистичный консольный “bitcoin-кошелёк”
Описание задачи
Разработайте консольный скрипт для сети bitcoin testnet, который будет:
- генерировать и сохранять в файл в собственной директории приватный ключ для
одного биткоин-адреса
- показывать баланс средств на данном адресе
- отправлять указанное количество средств на указанный пользователем другой
адрес
- Перед отправкой скрипт должен проверять, достаточно ли средств для отправки (включая
комиссию майнерам).
- Комиссия майнерам должна составлять 0.0001 tBTC.

Бонусные баллы (можно выполнить любое количество из нижеперечисленных пунктов,
указаны примерно в порядке нарастания сложности):
- Напишите Dockerfile и docker-compose.yml, позволяющие запустить скрипт
локально в докере
- Рассчитывайте комиссию майнерами пропорционально размеру (в байтах)
получившейся транзакции
---------------------------------------------------------------------
### Задача выполнена, доп. задание с Докером выполнено.
####Файл с ключами лежит в текущей директории, в нем сохраняются все ключи ко всем адресам, тк терять ключи от прошлых адресов плохая практика, они могут пригодиться, вдруг кто-то случайно отправит транзакцию на старый адрес.
####Расчет комисси майнерам не сделан, но там все понятно. Есть вопрос по времени майнинга, от этого зависит формула расчета. Поэтому не стал делать.
---------------------------------------------------------------------
Для запуска контейнера надо в консоли перейти в директорию bitcoin_wallet и запустить 2 команды:

```bash
docker build -t bitcoin_wallet .
```
```bash
docker run -it -v "$(pwd)":/keys bitcoin_wallet
```

#### Вторая часть задания - трудоемкая и не оригинальная, готов ее сделать на рельсах с Angular или JS(Jquery), если потребуется если это важно.
