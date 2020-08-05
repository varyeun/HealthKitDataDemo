# HealthKitDataDemo
swift HealthKit &amp; CoreLocation &amp; CoreMotion example

All Codes Created by @varyeun while I was working for ADUP.


목차

	Apple 개발 공식 관련 문서 링크
	필요한 프로젝트 기본 설정
	데이터 기록 양식 설명
	데이터 타입, 설명 및 추출 가능한 값



	Apple 개발 공식 관련 문서 링크

https://developer.apple.com/documentation/healthkit/hkobjecttype

위의 문서에서 자신이 원하는 데이터의 타입을 찾아 해당 타입, Identifier에서 불러온다.
모든 데이터는 객체로 되어있다. 데이터 값은 HKSampleQuery (A general query that returns a snapshot of all the matching samples currently saved in the HealthKit store.) 를 통해서 불러와야 하고, Identifier에 따른 HKSample 타입에 따라 받아올 수 있는 데이터가 문서 내 “Getting Property Data”에 명시되어있다.

https://developer.apple.com/documentation/corelocation/cllocation

위는 기기의 위치 데이터 관련 문서이다.



	필요한 프로젝트 기본 설정

1.	프로젝트의 Capabilities에 HealthKit 추가
2.	Info.plist에 Privacy - Health Update Usage Description (건강 기록을 쓸 경우), Privacy - Health Share Usage Description (건강 기록 읽어 올 경우), Privacy - Location When In Use Usage Description (위치 데이터 접근) 과 같은 Key를 추가하고, Value에는 사용자에게 해당 데이터들을 갖고 와도 되는지에 대한 접근 권한 요청 메시지를 작성한다. (일정 길이 이상 작성하지 않으면 반려되므로 최소 12글자 이상 작성할 것)
3.	HealthKit에서 가져오는 모든 데이터는 데이터가 속한 카테고리마다 권한을 받아야 하고, 이를 샘플 코드 내의 “Authorize” 버튼에 구현해두었다. 샘플 코ㄴ드는 권한을 얻는 동작을 버튼으로 따로 구현해두었기 때문에 처음 이 코드를 실행할 때, 특정 데이터를 처음 받아올 때는 꼭 해당 버튼을 눌러 권한을 얻어야 한다.
4.	실시간으로 측정하여 가져오는 데이터(gyro, 가속도 등)가 아닌 경우, “Get Details” 버튼을 눌렀을 때 데이터를 출력하도록 구현해두었다.
5.	“Update Weight” 버튼은 Health 데이터 쓰는 기능을 구현했던 버튼으로, 해당 기능 코드는 모두 주석처리 되어있어, 눌러도 아무 기능이 작동하지 않는 것이 정상이다.
6.	작성해 놓은 예시 코드와 애플 개발자 문서를 꼭! 참고할 것. 코드 내에서도 권한을 받아오는 등과 같은 함수 따로 또 구현 해야하는 등의 절차가 있기 때문이다.



	데이터 기록 양식 설명

필요한 데이터  추가 설명
(static) let/var 데이터명: 데이터타입
: 해당 데이터에 대한 설명
-	DB 고려한 추출가능한 데이터 항목
-	Value (해당 데이터에 맞는 데이터 타입)  단위 유무
-	Value 타입이 String인 데이터들은 단위가 출력되는 이유로 의도적으로 각 데이터들 타입(ex. HKQuantity)을 String으로 감싸서 추출함
-	Date (yyyy-MM-dd HH:mm:ss)
-	Date 값은 샘플 코드 내에서 DateFormatter로 포멧을 임의로 맞춰놓았음


HKQuantitySample이 가져올 수 있는 데이터
var quantity: HKQuantity
var count: Int
var quantityType: HKQuantityType



	데이터 타입, 설명 및 추출 가능한 값

Unique ID  ios 기기 고유 식별 값 (추출 시 String으로 타입 변환해두었음)
var identifierForVendor: UUID?
: An alphanumeric string that uniquely identifies a device to the app’s vendor.
-	Value(String) : UUID

걸음 수  걸음 수의 경우 “당일 0시부터 현재까지의 축척된 값”을 출력해야하기 때문에 HKStatisticsQuery 를 통해 구해야한다. 걸음 수를 구하는 함수를 예제 코드에 구현해 놓았다. (func getTodaysSteps)
static let stepCount: HKQuantityTypeIdentifier
: A quantity sample type that measures the number of steps the user has taken.
-	Value (Double) : stepCount  단위 안 붙어서 나옴
-	Date (yyyy-MM-dd HH:mm:ss)


체온
static let bodyTemperature: HKQuantityTypeIdentifier
: A quantity sample type that measures the user’s body temperature.
-	Value (String) : temperature  degC 라는 단위 붙어서 나옴
-	Date (yyyy-MM-dd HH:mm:ss)


기압  CMALtimeter와 func startRelativeAltitudeUpdates( ) 를 통해 가져와야 한다.
https://developer.apple.com/documentation/coremotion/cmaltitudedata
var pressure: NSNumber
: The recorded pressure, in kilopascals.
-	Value (Double) : pressure  단위 안 붙어서 나옴
-	Date (yyyy-MM-dd HH:mm:ss)


고도  CLLocationManager를 통해 CLLocation 받아서 가져와야한다.
var altitude: CLLocationDistance
:The altitude, measured in meters.
-	Value (Double) : altitude  단위 안 붙어서 나옴
-	Date (yyyy-MM-dd HH:mm:ss)


심박수
static let heartrate: HKQuantityTypeIdentifier
: A quantity sample type that measures the user’s heart rate.
-	Value (String) : heartrate  count/min 이라는 단위 붙어서 나옴
-	Date (yyyy-MM-dd HH:mm:ss)


Accelerometer (가속도)  CMMotionManager와 func startAccelerometerUpdates( )를 통해 가져와야한다.
var accelerometerData: CMAccelerometerData?
: The latest sample of accelerometer data.
-	Value (Double) x  단위 안 붙어서 나옴
-	Value (Double) y  단위 안 붙어서 나옴
-	Value (Double) z  단위 안 붙어서 나옴
-	Date (yyyy-MM-dd HH:mm:ss)


Gyro  CMMotionManager와 func startGyroUpdates( )를 통해 가져와야한다.
var gyroData: CMGyroData?
: The latest sample of gyroscope data.
-	Value (Double) x  단위 안 붙어서 나옴
-	Value (Double) y  단위 안 붙어서 나옴
-	Value (Double) z  단위 안 붙어서 나옴
-	Date (yyyy-MM-dd HH:mm:ss)
