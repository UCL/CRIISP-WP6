import fitbit
unauth_client = fitbit.Fitbit('23RBL4', '5584bef963882c9134273b0f77574bb5')

authd_client = fitbit.Fitbit('23RBL4', 
                             '5584bef963882c9134273b0f77574bb5',
                             access_token="eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIyM1JCTDQiLCJzdWIiOiJCUjZCUzUiLCJpc3MiOiJGaXRiaXQiLCJ0eXAiOiJhY2Nlc3NfdG9rZW4iLCJzY29wZXMiOiJ3aHIgd251dCB3cHJvIHdzbGUgd2VjZyB3c29jIHdhY3Qgd294eSB3dGVtIHd3ZWkgd2NmIHdzZXQgd2xvYyB3cmVzIiwiZXhwIjoxNjk3NDc4MDc0LCJpYXQiOjE2OTc0NDkyNzR9.sYn0ZCiYuotDdoPgvGuu_OyY6I7oNWSQug_2B93ShuY", 
                             refresh_token='c70b32c73a4244e0db1a882621f4c982b5f98ea5b88259b02f55af45227bf978')
                             
authd_client.activities()


