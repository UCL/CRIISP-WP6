import fitbit
unauth_client = fitbit.Fitbit('23RBL4', '<consumer_secret>')
# certain methods do not require user keys
unauth_client.food_units()
