/* @file rf_defs.h
 *
 *  Contains registers and constants used by the 
 *  Atmega128rfa1.
 *
 */

// AVR command defines

// command bits
#define TRX_CMD_MASK    (0x01F)

#define RF_SUCCESS  (0)
#define RF_ERROR    (-1)

#define RF_MAX_PACKET_LEN   (120)
