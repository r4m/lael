/*
 * Copyright (c) 2010, Department of Information Engineering, University of Padova.
 * All rights reserved.
 *
 * This file is part of Lael.
 *
 * Lael is free software: you can redistribute it and/or modify it under the terms
 * of the GNU General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Lael is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Lael.  If not, see <http://www.gnu.org/licenses/>.
 *
 * ===================================================================================
 */

/**
 *
 * Configuration file of the module SensorP.nc
 *
 * @date 26/07/2011 12:48
 * @author Filippo Zanella <filippo.zanella@dei.unipd.it>
 */

#include "../TmoteComm.h"

configuration SensorC
{}
implementation
{
	components MainC, LedsC;
	components SensorP as App;

	components new DemoSensorC() as VoltSensor;
	components new SensirionSht11C() as TempHumiSensor;
	components new HamamatsuS1087ParC() as LightSensor;

	components new TimerMilliC() as SamplingRadioClock;
	components new TimerMilliC() as SamplingSensorsClock;

	components SerialActiveMessageC as SAM;

	components CC2420ControlC;
	components CC2420ActiveMessageC as RAM;

	components new QueueC(radio_msg ,QUEUE_SIZE) as QueueBroadcast;

	App.Boot -> MainC.Boot;
	App.Leds -> LedsC.Leds;
	App.SamplingRadioClock -> SamplingRadioClock.Timer;
	App.SamplingSensorsClock -> SamplingSensorsClock.Timer;

	App.Voltage -> VoltSensor;
	App.Temperature -> TempHumiSensor.Temperature;
	App.Humidity -> TempHumiSensor.Humidity;
	App.Light -> LightSensor;

	App.AMCtrlSerial -> SAM;
	App.AMSendSerialS -> SAM.AMSend[AM_SENSORS_MSG];
	App.AMSendSerialR -> SAM.AMSend[AM_RADIO_MSG];

	App.CC2420Config -> CC2420ControlC.CC2420Config;
	App.InfoRadio -> RAM;
	App.AMCtrlRadio -> RAM;
	App.AMSendRadioR   -> RAM.AMSend[AM_RADIO_MSG];
	App.Receive  -> RAM.Receive[AM_RADIO_MSG];

	App.QueueBroadcast -> QueueBroadcast.Queue;
}
