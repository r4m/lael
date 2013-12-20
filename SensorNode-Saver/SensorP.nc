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
 * This is the application file.
 *
 * @date 01/06/2011 12:48
 * @author Filippo Zanella <filippo.zanella@dei.unipd.it>
 */

module SensorP
{
	uses
	{
		interface Leds;
		interface Boot;

		interface Timer<TMilli> as SamplingSensorsClock;
		interface Timer<TMilli> as SamplingRadioClock;

		interface SplitControl as AMCtrlSerial;
		interface AMSend as AMSendSerialS;
		interface AMSend as AMSendSerialR;

		interface Read<uint16_t> as Voltage;
		interface Read<uint16_t> as Temperature;
		interface Read<uint16_t> as Humidity;
		interface Read<uint16_t> as Light;

		interface CC2420Packet as InfoRadio;
		interface CC2420Config;
		interface SplitControl as AMCtrlRadio;
		interface Receive;
		interface AMSend as AMSendRadioR;

		interface Queue<radio_msg> as QueueBroadcast;
	}
}


implementation
{
	message_t serialPacket;
	message_t radioPacket;

	bool lockedSerial;
	bool lockedRadio;

	sensors_msg sm;

	uint16_t counterDiffRadioPckg;
	uint16_t counterSameRadioPckg;

	task void sendSerialS();
	task void sendSerialR();
	task void sendBroadcast();

	/******************************* Init *****************************/

	event void Boot.booted() {
		call Leds.set(000);

		lockedRadio = FALSE;
		lockedSerial = FALSE;

		counterDiffRadioPckg = 0;

		call CC2420Config.setChannel(CHANNEL_RADIO);
		call CC2420Config.sync();
	}

	event void CC2420Config.syncDone(error_t error) {
		if (error == SUCCESS)
			call AMCtrlRadio.start();
		else
			call CC2420Config.sync();
	}

	event void AMCtrlRadio.startDone(error_t err) {
		if (err == SUCCESS)
			call AMCtrlSerial.start();
		else
			call AMCtrlRadio.start();
	}

	event void AMCtrlSerial.startDone(error_t err) {
		if (err == SUCCESS) {
			call InfoRadio.setPower(&radioPacket,POWER_RADIO);
			call SamplingSensorsClock.startPeriodic(TIMER_SENSORS);
			call SamplingRadioClock.startPeriodic(TIMER_RADIO);
		}
		else { call AMCtrlSerial.start(); }
	}

	event void AMCtrlRadio.stopDone(error_t err) {}

	event void AMCtrlSerial.stopDone(error_t err){}

	/******************************* Sensors *****************************/

	event void SamplingSensorsClock.fired() {
		call Voltage.read();
	}

	event void Voltage.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) sm.voltage = data;
		else sm.voltage = 0xFFFF;

		call Temperature.read();
	}

	event void Temperature.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) sm.temperature = data;
		else sm.temperature = 0xFFFF;

		call Humidity.read();
	}

	event void Humidity.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) sm.humidity = data;
		else sm.humidity = 0xFFFF;

		call Light.read();
	}

	event void Light.readDone(error_t result, uint16_t data) {
		if (result == SUCCESS) sm.light = data;
		else sm.light = 0xFFFF;

		post sendSerialS();
	}

	/******************************* Serial *****************************/

	task void sendSerialS() {
		if(lockedSerial){}
		else {
			sensors_msg toSend = sm;
			sensors_msg* smp = (sensors_msg*)call AMSendSerialS.getPayload(&serialPacket, sizeof(sensors_msg));
			if (smp == NULL) {return;}

			atomic
			{
				smp->voltage = toSend.voltage;
				smp->temperature = toSend.temperature;
				smp->humidity = toSend.humidity;
				smp->light = toSend.light;
				smp->id = TOS_NODE_ID;
			}

			if (call AMSendSerialS.send(AM_BROADCAST_ADDR, &serialPacket, sizeof(sensors_msg)) == SUCCESS) {
				lockedSerial = TRUE;
			}
		}
	}

	event void AMSendSerialS.sendDone(message_t* msg, error_t error) {
		if (&serialPacket == msg) {
			lockedSerial = FALSE;
			//call Leds.led0Toggle();
		}
	}

	task void sendSerialR() {
		if(lockedSerial){}
		else {
			if(! call QueueBroadcast.empty()) {
				radio_msg rm = call QueueBroadcast.dequeue();
				radio_msg* rmp = (radio_msg*)call AMSendSerialR.getPayload(&serialPacket, sizeof(radio_msg));

				if (rmp == NULL) {return;}

				atomic
				{
					rmp->id  = rm.id;
					rmp->counter = rm.counter;
					rmp->rss    = rm.rss;
					rmp->rssi     = rm.rssi;
					rmp->lqi     = rm.lqi;
					rmp->channel = rm.channel;
					rmp->power   = rm.power;
				}

				if (call AMSendSerialR.send(AM_BROADCAST_ADDR, &serialPacket, sizeof(radio_msg)) == SUCCESS) {
					lockedSerial = TRUE;
				}
			}
		}

		if(! call QueueBroadcast.empty()) {
			post sendSerialR();
		}
	}

	event void AMSendSerialR.sendDone(message_t* msg, error_t error) {
		if (&serialPacket == msg) {
			lockedSerial = FALSE;
			//call Leds.led0Toggle();
		}
	}

	/******************************* Radio *****************************/

	event void SamplingRadioClock.fired() {
		counterDiffRadioPckg++;
		counterSameRadioPckg = 0;
		post sendBroadcast();
	}

	task void sendBroadcast() {
		if (!lockedRadio) {
			broadcast_msg* bm = (broadcast_msg*)(call AMSendRadioR.getPayload(&radioPacket, sizeof(broadcast_msg)));
			bm->id = TOS_NODE_ID;
			bm->counter = counterDiffRadioPckg;
			if (call AMSendRadioR.send(AM_BROADCAST_ADDR, &radioPacket, sizeof(broadcast_msg)) == SUCCESS) {
				lockedRadio = TRUE;
			}
		}
	}

	event void AMSendRadioR.sendDone(message_t* msg, error_t error) {
		if (&radioPacket == msg) {
			counterSameRadioPckg++;
			lockedRadio = FALSE;
		}

		if(counterSameRadioPckg<MAX_PCKG) {
			post sendBroadcast();
		}

	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		radio_msg rm;
		call Leds.led0Toggle();

		if (len == sizeof(broadcast_msg)) {
			broadcast_msg* bm = (broadcast_msg*)payload;
			atomic
			{
				rm.id  = bm -> id;
				rm.counter = bm -> counter;
				rm.rssi    = call InfoRadio.getRssi(msg);
				rm.rss     = rm.rssi + RSSI_OFFSET;
				rm.lqi     = call InfoRadio.getLqi(msg);
				rm.channel = call CC2420Config.getChannel();
				rm.power   = POWER_RADIO;
			}
			if((call QueueBroadcast.size()) < QUEUE_SIZE) {
				call QueueBroadcast.enqueue(rm);
			}
			post sendSerialR();
		}
		return msg;
	}
}
