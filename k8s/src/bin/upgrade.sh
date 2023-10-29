#!/bin/bash
# set -e

while ! nc -z $DB_HOST 3306;
do
    echo "Waiting for database...";
    sleep 1;
done;
echo "Database found";

# Check if Magento is installed and if the database needs to be upgraded.
tableCount=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME -B -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB_NAME';" | grep -v "count");
if [ $tableCount -gt 0 ]
then
    echo "Database is not empty";
    
    php -d memory_limit=2G bin/magento setup:db:status
    dbStatus=$?
    
    # Put the site under maintenance and upgrade the schema and data
    # It always returns 2: https://github.com/magento/magento2/issues/19597
    if [ $dbStatus == 2 ]
    then
        echo "Need to run the upgradee";
        php bin/magento maintenance:enable;
        php -d memory_limit=2G bin/magento setup:upgrade --keep-generated;
        php bin/magento maintenance:disable;
        echo "Database upgrade is completed";
    fi
fi