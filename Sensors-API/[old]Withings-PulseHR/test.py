from withings_api import WithingsAuth, WithingsApi, AuthScope
from withings_api.common import get_measure_value, MeasureType


auth = WithingsAuth(
    client_id='be15110fa9ce5d7f43eb15bd76fdf3ee84c6f25e1f7912db8bfa942d4556058a',
    consumer_secret='fcce82841dec18cc5b11be776412423b970d26377eb1f7dab8f3f645f030aad9',
    callback_uri='http://localhost:1410/',
#    mode='demo',  # Used for testing. Remove this when getting real user data.
#    scope=(
#        AuthScope.USER_ACTIVITY,
#        AuthScope.USER_METRICS,
#        AuthScope.USER_INFO,
#        AuthScope.USER_SLEEP_EVENTS,
#    )
)


authorize_url = auth.get_authorize_url()
# Have the user goto authorize_url and authorize the app. They will be redirected back to your redirect_uri.

