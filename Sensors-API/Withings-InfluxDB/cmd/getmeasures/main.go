package main

import (
	"fmt"
	"math"
	"os"
	"time"

	"github.com/artoo-git/withings-go/withings"
)

const (
	tokenFile = "access_token.json"
	layout    = "2006-01-02"
	layout2   = "2006-01-02 15:04:05"
	isnotify  = false
)

var (
	loc        *time.Location
	t          time.Time
	adayago    time.Time
	lastupdate time.Time
	ed         string
	sd         string
	client     *(withings.Client)
	settings   map[string]string
)

func auth(settings map[string]string) {
	var err error
	client, err = withings.New(settings["CID"], settings["Secret"], settings["RedirectURL"])

	if err != nil {
		fmt.Println("Failed to create New client")
		fmt.Println(err)
		return
	}

	if _, err := os.Open(tokenFile); err != nil {
		var e error

		client.Token, e = withings.AuthorizeOffline(client.Conf)
		client.Client = withings.GetClient(client.Conf, client.Token)

		if e != nil {
			fmt.Println("Failed to authorize offline.")
		}
		fmt.Println("~~ authorized. Let's check the token file!")
	} else {
		_, err = client.ReadToken(tokenFile)

		if err != nil {
			fmt.Println("Failed to read token file.")
			fmt.Println(err)
			return
		}
	}
}

func tokenFuncs() {
	// Show token
	client.PrintToken()

	// Refresh Token if you need
	_, rf, err := client.RefreshToken()
	if err != nil {
		fmt.Println("Failed to RefreshToken")
		fmt.Println(err)
		return
	}
	if rf {
		fmt.Println("You got new token!")
		client.PrintToken()
	}

	// Save Token if you need
	err = client.SaveToken(tokenFile)
	if err != nil {
		fmt.Println("Failed to RefreshToken")
		fmt.Println(err)
		return
	}
}

func mainSetup() {
	var err error
	loc, err = time.LoadLocation("Local")
	if err != nil {
		fmt.Println("Failed to load location:", err)
		return
	}
	//t = time.Now()
	t = time.Date(2024, 2, 15, 0, 0, 0, 0, loc) // I set this now for testing old data
	// to get sample data from 2 days ago to now
	adayago = t.Add(-48 * time.Hour)
	ed = t.Format(layout)
	sd = adayago.Format(layout)
	lastupdate = withings.OffsetBase
}

func printMeas(v withings.MeasureData, name, unit string) {
	fmt.Printf("%s(Grpid:%v, Category:%v, Attrib: %v, DeviceID:%v)\n", name, v.GrpID, v.Category, v.Attrib, v.DeviceID)
	fmt.Printf("%v, %.1f %s\n", v.Date.In(loc).Format(layout2), v.Value, unit)
}

func testGetmeas() {

	fmt.Println("========== Getmeas[START] ========== ")
	mym, err := client.GetMeas(withings.Real, adayago, t, lastupdate, 0, false, true, withings.Weight, 
																					  withings.Height, 
																					  withings.FatFreeMass, 
																					  withings.BoneMass, 
																					  withings.FatRatio, 
																					  withings.FatMassWeight, 
																					  withings.Temp, 
																					  withings.HeartPulse, 
																					  withings.Hydration)
	if err != nil {
		fmt.Println(err)
		return
	}

	fmt.Printf("Status: %d\n", mym.Status)

	for _, v := range mym.SerializedData.Weights {
		printMeas(v, "Weight", "Kg")
	}
	for _, v := range mym.SerializedData.FatFreeMass {
		printMeas(v, "FatFreeMass", "Kg")
	}
	for _, v := range mym.SerializedData.FatRatios {
		printMeas(v, "FatRatio", "%%")
	}
	for _, v := range mym.SerializedData.FatMassWeights {
		printMeas(v, "FatMassWeight", "Kg")
	}
	for _, v := range mym.SerializedData.BoneMasses {
		printMeas(v, "BoneMass", "Kg")
	}

	for _, v := range mym.SerializedData.UnknowVals {
		printMeas(v, "UnknownVal", "N/A")
	}

	// Raw data should be provided from mym.Body.Measuregrps
	for _, v := range mym.Body.Measuregrps {
		weight := float64(v.Measures[0].Value) * math.Pow10(v.Measures[0].Unit)
		fmt.Printf("Weight:%.1f Kgs\n", weight)
	}
	fmt.Printf("More:%d, Offset:%d\n", mym.Body.More, mym.Body.Offset)

	fmt.Println("========== Getmeas[END] ========== ")
}

func testGetactivity() {

	fmt.Println("========== Getactivity[START] ========== ")

	act, err := client.GetActivity(sd, ed, 0, 0, withings.Steps,     // n.step
												 withings.Distance,  // est. meters traveled
												 withings.Elevation, // meters climbed

												 withings.Soft,      // Duration of soft activities (in seconds)
												 withings.Moderate,  // Duration of Moderate activities (in seconds)
												 withings.Intense,   // Duration of Intense activities (in seconds)
												 withings.Active,    // Duration of activities (in seconds)

											     withings.Calories,      // Active calories burned (in Kcal).
											     withings.TotalCalories, // Total sum of daily calories Basel

											     withings.HrAverage,     // Average heart rate.
											     withings.HrMin,         // Min heart rate.
											     withings.HrMax,         // Max heart rate.
											 	 withings.HrZone0,       // Duration in seconds when heart rate was in a light zone
											 	 withings.HrZone1,       // Duration in seconds when heart rate was in a Moderate zone
											 	 withings.HrZone2,       // Duration in seconds when heart rate was in a Intense zone
											 	 withings.HrZone3)       // Duration in seconds when heart rate was in a Maximal zone

	if err != nil {
		fmt.Println("getActivity Error.")
		fmt.Println(err)
		return
	}

	//fmt.Println(act)
	for _, v := range act.Body.Activities {
		fmt.Printf("Date:%s, Steps:%d, Distance:%.1f, Elevation:%.1f, BurnedCalories: %.1f, TotCalories: %.1f, " +
			       "TimeSoft:%d, TimeMod:%d, TimeInt:%d, TimeAct:%d, "  +
				   "HRAverage: %.1f, HRMinimum: %d, HRMax:%d, HRzone0:%d, HRzone1:%d, HRzone2:%d, HRzone3:%d \n", 
			       v.Date, v.Steps, v.Distance, v.Elevation, v.Calories, v.Totalcalories,
			       v.Soft, v.Moderate, v.Intense, v.Active,  
			       v.HrAverage, v.HrMin, v.HrMax, v.HrZone0, v.HrZone1, v.HrZone2, v.HrZone3)
	}

	fmt.Println("========== Getactivity[END] ========== ")
}

func testGetworkouts() {

	fmt.Println("========== Getworkouts[START] ========== ")

	workouts, err := client.GetWorkouts(sd, ed, 0, 0, withings.WTCalories, 
													  withings.WTSteps, 
													  withings.WTDistance,
													  withings.WTHrMin,
													  withings.WTHrMax)

	if err != nil {
		fmt.Println("getWorkouts Error.")
		fmt.Println(err)
		return
	}

	for _, v := range workouts.Body.Series {
		fmt.Printf("Date:%s, Category: %d, Duration: %d, Steps:%d, Distance:%.1f, Calories: %.1f, HrMin: %d, HrMax: %d \n", 
			       v.Date, v.Category, v.Data.Effduration, v.Data.Steps, v.Data.Distance, v.Data.Calories,v.Data.HrMin, v.Data.HrMax)
	}
	fmt.Println("========== Getworkouts[END] ========== ")
}

func testGetsleep() {
	fmt.Println("========== Getsleep[START] ========== ")

	slp, err := client.GetSleep(adayago, t, 
								withings.HrSleep,
								withings.RrSleep, 
								withings.SnoringSleep)
	if err != nil {
		fmt.Println("getSleep Error!")
		fmt.Println(err)
		return
	}
	for _, v := range slp.Body.Series {
		st := ""
		switch v.State {
		case int(withings.Awake):
			st = "Awake"
		case int(withings.LightSleep):
			st = "LightSleep"
		case int(withings.DeepSleep):
			st = "DeepSleep"
		case int(withings.REM):
			st = "REM"
		default:
			st = "Unknown"
		}
		stimeUnix := time.Unix(v.Startdate, 0)
		etimeUnix := time.Unix(v.Enddate, 0)

		stime := (stimeUnix.In(loc)).Format(layout2)
		etime := (etimeUnix.In(loc)).Format(layout2)
		message := fmt.Sprintf("%s to %s: %s, Hr:%d, Rr:%d, Snoring:%d \n", stime, etime, st, v.Hr, v.Rr, v.Snoring)
		fmt.Printf(message)
	}
	//fmt.Println(slp)
	fmt.Println("========== Getsleep[END] ========== ")

}

func testGetsleepsummary() {
	fmt.Println("========== Getsleepsummary[START] ========== ")

	slpsum, err := client.GetSleepSummary(sd, ed, 0, 
		withings.SSDsd, withings.SSDsli, withings.SSRsdur,
		withings.SSD2s, withings.SSD2w, 
		withings.SSHrAvr, withings.SSHrMax, withings.SSHrMin, 
		withings.SSWupC, withings.SSWupD,
		withings.SSSS, // sleep score
		withings.SSSng, withings.SSSngEC, // snooring episode & count
		withings.SSBdi, 
		withings.SSRRAvr, withings.SSRRMax, withings.SSRRMin,
		)

	if err != nil {
		fmt.Println("getSleepSummary Error!")
		fmt.Println(err)
		return
	}
	for _, v := range slpsum.Body.Series {
		stimeUnix := time.Unix(v.Startdate, 0)
		etimeUnix := time.Unix(v.Enddate, 0)

		stime := (stimeUnix.In(loc)).Format(layout2)
		etime := (etimeUnix.In(loc)).Format(layout2)
		message := fmt.Sprintf(
			"%s-%s: deep sleep duration(sec):%d, light sleep duration(sec):%d, REM sleep duration(sec):%d, duration to sleep(sec):%d, duration to wakeup(sec):%d,HrAverage:%d, Max:%d, Min:%d, WakeupCounts:%d, Wakeupduration:%d, SleepScore %d, Snoring %d, Snoring ep. count %d,BDI:%d, RrAverage:%d, RrMax:%d, RrMin:%d",
			stime, etime, 
			v.Data.Deepsleepduration, v.Data.Lightsleepduration, v.Data.Remsleepduration,
			v.Data.Durationtosleep, v.Data.Durationtowakeup, 
			v.Data.HrAverage, v.Data.HrMax, v.Data.HrMin, 
			v.Data.Wakeupcount,v.Data.Wakeupduration,
			v.Data.SleepScore,
			v.Data.Snoring,v.Data.Snoringepisodecount,
			v.Data.BreathingDisturbancesIntensity, 
			v.Data.RrAverage,v.Data.RrMax,v.Data.RrMin)
		fmt.Println(message)
	}
	//fmt.Println(slpsum)
	fmt.Println("========== Getsleepsummary[END] ========== ")
}

func main() {

	settings = withings.ReadSettings(".settings.yaml")

	auth(settings)
	tokenFuncs()
	mainSetup()

//	testGetmeas()
//	testGetactivity()
//	testGetworkouts()
//	testGetsleep()
	testGetsleepsummary()
}