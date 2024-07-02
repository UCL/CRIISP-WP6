###  Python-Fitbit documentation master file, created by
###     sphinx-quickstart on Wed Mar 14 18:51:57 2012.
###     You can adapt this file completely to your liking, but it should at least
###     contain the root `toctree` directive.
###  
###  Overview
###  ========
###  
###  This is a complete python implementation of the Fitbit API.
###  
###  It uses oAuth for authentication, it supports both us and si
###  measurements
###  
###  Quickstart
###  ==========
###  
###  If you are only retrieving data that doesn't require authorization, then you can use the unauthorized interface::
###  
###      import fitbit
###      unauth_client = fitbit.Fitbit('<consumer_key>', '<consumer_secret>')
###      # certain methods do not require user keys
###      unauth_client.food_units()
###  
###  Here is an example of authorizing with OAuth 2.0::
###  
###      # You'll have to gather the tokens on your own, or use
###      # ./gather_keys_oauth2.py
###      authd_client = fitbit.Fitbit('<consumer_key>', '<consumer_secret>',
###                                   access_token='<access_token>', refresh_token='<refresh_token>')
###      authd_client.sleep()
###  

#%matplotlib inline
import matplotlib.pyplot as plt
import fitbit

# gather_keys_oauth2.py file needs to be in the same directory. 
# also needs to install cherrypy: https://pypi.org/project/CherryPy/
# pip install CherryPy
import gather_keys_oauth2 as Oauth2
import pandas as pd 
import datetime


# YOU NEED TO PUT IN YOUR OWN CLIENT_ID AND CLIENT_SECRET
CLIENT_ID='23RBL4'
CLIENT_SECRET='5584bef963882c9134273b0f77574bb5'

server=Oauth2.OAuth2Server(CLIENT_ID, CLIENT_SECRET)
server.browser_authorize()
ACCESS_TOKEN=str(server.fitbit.client.session.token['access_token'])
REFRESH_TOKEN=str(server.fitbit.client.session.token['refresh_token'])
auth2_client=fitbit.Fitbit(CLIENT_ID,CLIENT_SECRET,oauth2=True,access_token=ACCESS_TOKEN,refresh_token=REFRESH_TOKEN)




unauth_client = fitbit.Fitbit('23RBL4', '5584bef963882c9134273b0f77574bb5')

authd_client = fitbit.Fitbit('23RBL4', 
                             '5584bef963882c9134273b0f77574bb5',
                             access_token="eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyM1JCTDQiLCJzdWIiOiJCUjZCUzUiLCJpc3MiOiJGaXRiaXQiLCJ0eXAiOiJhY2Nlc3NfdG9rZW4iLCJzY29wZXMiOiJ3aHIgd251dCB3cHJvIHdzbGUgd2VjZyB3c29jIHdhY3Qgd294eSB3dGVtIHd3ZWkgd2NmIHdzZXQgd2xvYyB3cmVzIiwiZXhwIjoxNjk3NDc4MDc0LCJpYXQiOjE2OTc0NDkyNzR9.sYn0ZCiYuotDdoPgvGuu_OyY6I7oNWSQug_2B93ShuY", 
                             refresh_token='c70b32c73a4244e0db1a882621f4c982b5f98ea5b88259b02f55af45227bf978')
                             
authd_client.activities()

###  Fitbit API
###  ==========
###  
###  Some assumptions you should note. Anywhere it says user_id=None,
###  it assumes the current user_id from the credentials given, and passes
###  a ``-`` through the API.  Anywhere it says date=None, it should accept
###  either ``None`` or a ``date`` or ``datetime`` object
###  (anything with proper strftime will do), or a string formatted
###  as ``%Y-%m-%d``.
###  
###  .. autoclass:: fitbit.Fitbit
###      :members:
###  
###      .. method:: body(date=None, user_id=None, data=None)
###  
###         Get body data: https://dev.fitbit.com/docs/body/
###  
###      .. method:: activities(date=None, user_id=None, data=None)
###  
###         Get body data: https://dev.fitbit.com/docs/activity/
###  
###      .. method:: foods_log(date=None, user_id=None, data=None)
###  
###         Get food logs data: https://dev.fitbit.com/docs/food-logging/#get-food-logs
###  
###      .. method:: foods_log_water(date=None, user_id=None, data=None)
###  
###         Get water logs data: https://dev.fitbit.com/docs/food-logging/#get-water-logs
###  
###      .. method:: sleep(date=None, user_id=None, data=None)
###  
###         Get sleep data: https://dev.fitbit.com/docs/sleep/
###  
###      .. method:: heart(date=None, user_id=None, data=None)
###  
###         Get heart rate data: https://dev.fitbit.com/docs/heart-rate/
###  
###      .. method:: bp(date=None, user_id=None, data=None)
###  
###         Get blood pressure data: https://dev.fitbit.com/docs/heart-rate/
###  
###      .. method:: delete_body(log_id)
###  
###         Delete a body log, given a log id
###  
###      .. method:: delete_activities(log_id)
###  
###         Delete an activity log, given a log id
###  
###      .. method:: delete_foods_log(log_id)
###  
###         Delete a food log, given a log id
###  
###      .. method:: delete_foods_log_water(log_id)
###  
###         Delete a water log, given a log id
###  
###      .. method:: delete_sleep(log_id)
###  
###         Delete a sleep log, given a log id
###  
###      .. method:: delete_heart(log_id)
###  
###         Delete a heart log, given a log id
###  
###      .. method:: delete_bp(log_id)
###  
###         Delete a blood pressure log, given a log id
###  
###      .. method:: recent_foods(user_id=None, qualifier='')
###  
###         Get recently logged foods: https://dev.fitbit.com/docs/food-logging/#get-recent-foods
###  
###      .. method:: frequent_foods(user_id=None, qualifier='')
###  
###         Get frequently logged foods: https://dev.fitbit.com/docs/food-logging/#get-frequent-foods
###  
###      .. method:: favorite_foods(user_id=None, qualifier='')
###  
###         Get favorited foods: https://dev.fitbit.com/docs/food-logging/#get-favorite-foods
###  
###      .. method:: recent_activities(user_id=None, qualifier='')
###  
###         Get recently logged activities: https://dev.fitbit.com/docs/activity/#get-recent-activity-types
###  
###      .. method:: frequent_activities(user_id=None, qualifier='')
###  
###         Get frequently logged activities: https://dev.fitbit.com/docs/activity/#get-frequent-activities
###  
###      .. method:: favorite_activities(user_id=None, qualifier='')

