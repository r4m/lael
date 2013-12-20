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
 * Header file.
 *
 * @date 26/07/2011 12:48
 * @author Filippo Zanella <filippo.zanella@dei.unipd.it>
 */ 

#ifndef TMOTE_COMM_H
#define TMOTE_COMM_H

#define TIMER_RADIO 0x57E40 // [ms] (6 minutes)
#define TIMER_SENSORS 0xAFC80 // [ms] (12 minutes)

//#define TIMER_RADIO 0xFA0 // [ms] (4 seconds)
//#define TIMER_SENSORS 0x3E80 // [ms] (10 seconds)

enum
{
  RSSI_OFFSET = -35,      // !!!Empiric!!! [dBm]
  QUEUE_SIZE = 30,       // Dimension of the FIFO stack

  TIMER_SEND = 50,    // Clock for the [ms]
  MAX_PCKG = 15,        // Maximum number of packet to send
  CHANNEL_RADIO = 6,  // Radio channel
  POWER_RADIO = 31,   // Power of the radio CC2420 [dBm] 
 
  AM_SENSORS_MSG = 0x19,    
  AM_RADIO_MSG = 0x29,     // both for radio_msg and p2p_msg
};

typedef nx_struct sensors_msg 
{
  nx_uint8_t id;         // ID of the sensor
  nx_uint16_t counter;       // ID of the received packet [n-th]
  nx_uint16_t voltage;       // [RAW] Voltage
  nx_uint16_t temperature;   // [RAW] Temperature 
  nx_uint16_t humidity;      // [RAW] Humidity 
  nx_uint16_t par;         // [RAW] PAR
  nx_uint16_t tsr;         // [RAW] TSR
} sensors_msg_t;


typedef nx_struct broadcast_msg
{
  nx_uint16_t id;   // ID of the sensor
  nx_uint16_t counter;  // ID of the sent packet [n-th]
} broadcast_msg_t;

typedef nx_struct radio_msg 
{
  nx_uint16_t id;         	  // ID of the sensor
  nx_uint16_t counter;        // ID of the received packet [n-th]
  nx_int16_t  rssi;           // RSSI [dBm] received signal strength indicator
  nx_int16_t  rss;            // RSS [dBm] received signal strength
  nx_int16_t  lqi;            // LQI [dBm] link quality indicator
  nx_uint8_t  channel;        // Transmission frequency 
  nx_uint8_t  power;          // Transmission power [dBm] 
} radio_msg_t;

#endif
