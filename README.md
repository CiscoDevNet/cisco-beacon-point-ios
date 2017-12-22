![](http://www.ciscolive.com/global/wp-content/uploads/cisco-logo-blue.png)
#Releases:
- 12/21/17 - Released MistSDK 1.2.0
- 11/20/17 - Released MistSDK 1.1.2
- 10/10/17 - Released MistSDK 1.1.1
- 8/29/17 - Released MistSDK 1.1.0
- 7/22/17 - Released MistSDK 0.0.1144
- 6/13/17 - Released MistSDK 0.0.1135

--

|  Contents |  Description | Status |
|---|---|---|
|  Sample-iOS | The source code for the Sample app that has everything you need to get started with indoor location. | Current |


## Getting Started ##
This is a sample iOS mobile app that demonstrates indoor bluedot and indoor way finding experience using Cisco's latest bluetooth Beacon Point - AIR-VBLE1-K9. Before we start using this app, you need to create an account at Cisco CMX Cloud https://cmxcloud.cisco.com installed the Beacon Points (BPs) at your indoor venue, configured them properly and integrate them with the Cisco CMX Cloud. You need to setup some paths and some virtual beacons at your indoor venue using the Cisco CMX Cloud. The aim of this app, is to track your device running this app inside your indoor venue. More details on this will be added soon. Once you have created the organization at Cisco CMX Cloud you will have a QR Code generated for your organization that will be used by the mobile app to connect to this organization.

## How to get started with this sample app
•	Checkout this project 

•	From Terminal  moved to project checkout directory ‘~/cisco-ios/Sample-iOS’ then run `pod install`

•	Open the workspace file

•	When project get loaded you can see your project structure something like below

<img src="http://gdurl.com/VMQ8" height="50%" width="50%">

•	Now just run the app to connected device using that play button in xcode.

•	Please provide all the permission needed for the app to get started

•	Now you can use ‘Add Organization’ Button followed by ‘QR Code’ button to scan the QR code of your organization to add your organization.

•	If QR code was correct you will see the entry of the environment something like this

<img src="http://gdurl.com/5MUD" height="30%" width="30%">

•	You can click on the configuration added in this case ‘test’. For entering to your org.

•	For blue dot experience select ‘FloorPlan Demo’ option

•	You are now able to get the blue dot on your floorplan.

<img src="http://gdurl.com/ujUT" height="30%" width="30%">


##  Integrating Mist SDK 
•	If using pod use can use  `pod 'MistSDK'`
			Or 
•	if using .framework, Download Mist SDK framework from [here](https://github.com/mistsys/cisco-ios/tree/master/Frameworks)

**Adding Framework in project**

•	Navigate to General tab of your App Target

•	Click on ‘+’ of Embedded Binaries 

•	Click ‘Add Others’

•	Select the .Framework and click ‘Open’

•	Select checkbox Copy items if needed and select create folder reference

•	Build the project

<img src="http://gdurl.com/VMQ8" height="50%" width="50%">


**Initializing Mist SDK**
  
   1. To initialize Mist SDK we need  Org Secret and Org Id.To get these details we have to enroll the Device with the invitation secret.
	
```
[MSTOrgCredentialsManager enrollDeviceWithToken:@"Invitation_secret" onComplete:^(NSDictionary *response, NSError *error) { }];
```
	-Invitation_secret : you can create one from mist portal Organization -> Mobile SDK
	-response :
		{
    		"secret": "your org secret required to initialize sdk",
    		"org_id": "your orgid",
    		"name": "your invitation name"
		}

   2. Initialize Mist SDK with org secret received, by creating MSTCentralManager object
   
```
@property (nonatomic, strong) MSTCentralManager *mistManager;
...
__weak __typeof__(self) weakSelf = self;
...

weakSelf.mistManager = [[MSTCentralManager alloc] initWithOrgID:response[@"org_id"] AndOrgSecret:response[@"secret"]];
```
	-response: is received from the 1st point


   3. Call start API of MSTCentralManager
```
    Setting app state is important that too on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
    [weakSelf.mistManager setAppState:[[UIApplication sharedApplication] applicationState]];
    [weakSelf.mistManager startLocationUpdates];
    });
```

**Listening to Location response from Mist SDK**

To get location information from Mist SDK you need to implement **MSTCentralManagerDelegate** callbacks in your ViewController

```
...
@interface ViewController () <MSTCentralManagerDelegate>
... 
weakSelf.mistManager.delegate = weakSelf;
...
```
**Major callbacks are**
   
   		/**
		* Returns updated location of the mobile client (as a point (X, Y) measured in meters from the map origin, i.e., relative X, Y)
		*/
```
- (void)mistManager:(MSTCentralManager *)manager didUpdateRelativeLocation:(MSTPoint *)relativeLocation inMaps:(NSArray *)maps at:(NSDate *)dateUpdated {  }
```




		/**
		* Returns updated location of the mobile client (as Latitude, Longitude – LatLng object, if the geolocation of map origin is available) 
		*/
```
- (void)mistManager:(MSTCentralManager *)manager didUpdateLocation:(CLLocationCoordinate2D)location inMaps:(NSArray *)maps withSource:(SourceType)locationSource at:(NSDate *)dateUpdated { }
```




		/**
		* Returns updated map for the mobile client 
		*/
```
- (void)mistManager:(MSTCentralManager *)manager didUpdateMap:(MSTMap *)map at:(NSDate *)dateUpdated { }
```




		/**
		* Returns the notification received that is targetted for the mobile client
		*/
```
- (void)mistManager:(MSTCentralManager *)manager didReceiveNotificationMessage:(NSDictionary *)payload { }
```




		/**
		* Returns the Arraylist of beacons that were found.
		*/
```
- (void)mistManager:(MSTCentralManager *)manager beaconsSent:(NSMutableArray *)beacons { }
```




		/**
		* Returns the HashMap of beacons with UUID as the key, that are found in the organization
		*/
```
- (void)mistManager:(MSTCentralManager *)manager didUpdateBeaconList:(NSArray *)beaconUuids at:(NSDate *)dateUpdated { }
```



		/**
		* Returns updated pressure when available to the app. The pressure will be a double measured in millibars
		*/
```
 - (void)mistManager:(MSTCentralManager *)manager didUpdatePressure:(double)pressure at:(NSDate *)dateUpdated { }
```



        /**
        * Returns the Array of beacons that were heard in the second
        */
```
-(void)mistManager:(MSTCentralManager *)manager didUpdateBeaconList:(NSArray *) beaconList at: (NSDate *) dateUpdated { }
```
       /**
        * Returns the status of SDK connection
        */
```
-(void)mistManager:(MSTCentralManager *)manager didConnect:(BOOL)isConnected { }
```

**MSTPoint :**

	 double x    		    : relative x
	 double y    		    : relative y
	 bool hasMotion   	    : is user in motion
	 MSTPointType mstPointType  : type Cloud,LastKnown,Device
	 double latency    	    : latency in network
	 double heading             : compass heading
	 bool headingFlag           : availability of compass heading
	 


**Other callbacks are**

		/**
		* Returns an array of virtual beacons associated with the current map
		*/
```
- (void)mistManager:(MSTCentralManager *)manager didReceivedVirtualBeacons:(NSDictionary *)virtualBeacons { }
```



		/**
		* Returns Client information that
		*/
```
- (void)mistManager:(MSTCentralManager *)manager didReceivedClientInformation:(NSDictionary *)clientInformation { }
```



		/**
		* Notifies the host application about the state of the MSTCentralManager status
		*/
```
-(void)manager:(MSTCentralManager *) manager receivedLogMessage: (NSString *)message forCode:(MSTCentralManagerStatusCode)code{ }
```



		/**
		* Notifies the host application about the verbose state of the MSTCentralManager status
		*/
```
-(void)manager:(MSTCentralManager *) manager receivedVerboseLogMessage:(NSString *)message{ }
```


**Setting up background app setting and configuring wakup time and sleep time**    
 
 ```objc 
 [weakSelf.mistManager wakeUpAppSetting:YES];
 [weakSelf.mistManager backgroundAppSetting:YES];
 [weakSelf.mistManager setSentTimeInBackgroundInMins:0.5 restTimeInBackgroundInMins:5];
 
 ```
 **Setting up background app setting for SDK to be running long time without any rest time**    
 
 ```objc 
 [weakSelf.mistManager wakeUpAppSetting:YES];
 [weakSelf.mistManager backgroundAppSetting:YES];
 [weakSelf.mistManager sendWithoutRest];
 
 ```
 
 **Stop SDK**

	To stop receiving callbacks from mist cloud use following
```
	[weakSelf.mistManager stopLocationUpdates];
```
