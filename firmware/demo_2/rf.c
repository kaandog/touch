/** @file rf.c
 *  @brief includes atmega128rfa1 rf functionality
 */
#include <inttypes.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <stdio.h>

#include "rf.h"

#define ACK_INTERRUPT(x) (IRQ_STATUS = (1 << (x)))
#define GET_TRX_STATE() (TRX_STATE & 0xF1)

void (*g_rx_callback) (void) = NULL;
void (*g_tx_callback) (void) = NULL;

SIGNAL(TRX24_RX_END_vect)
{
    int i;
    volatile uint8_t *rx_b = &TRXFBST;
    
    printf("\r\n");
    for(i = 0; i < TST_RX_LENGTH; i++)
    {
        printf("%c", (char) rx_b[i]);
    }
    
    printf("\r\n");
   
    ACK_INTERRUPT(RX_END);
    
    if (g_rx_callback)
    {
        g_rx_callback();
    }
    

    return;
}

SIGNAL(TRX24_TX_END_vect)
{
    printf("TX_DONE IRQ\r\n");
    ACK_INTERRUPT(TX_END);
    return;
}

/** @brief blocking state change
 */
void rf_change_state(uint8_t cmd)
{
    // wait for a previous state transition to finish
    while(GET_TRX_STATE() == STATE_TRANSITION_IN_PROGRESS)
        continue;
    
    TRX_STATE = cmd;

    // wait for this state transition to finish
    while(GET_TRX_STATE() == STATE_TRANSITION_IN_PROGRESS)
        continue;
}

/* @brief enable all rf interrupts
 */
void rf_enable_int(void)
{
    // enable all rf and tx interrupts
    IRQ_MASK = (1 << TX_END_EN) | (1 << RX_END_EN);
}

/* @brief disable all rf interrupts
 *
 *  Will likely be used to prevent race conditions
 *  since we don't ahve time to implement mutexes.
 */
void rf_disable_int(void)
{
    IRQ_MASK = 0;
}

/* @brief writes a command to trx_state
 */
void rf_trx_cmd(uint16_t cmd)
{

    TRX_STATE = (cmd & TRX_CMD_MASK) | (TRX_STATE & TRX_CMD_MASK);
}

void rf_rx_packet(uint8_t *buffer, uint8_t *len)
{
    int i, rx_len;
    volatile uint8_t *rx_buf = &TRXFBST;
    
    /* TODO: maybe dynamic frame buffer protection */
    rx_len = TST_RX_LENGTH;
    *len  = rx_len;
    
    for (i = 0; i < rx_len; i++)
    {
        buffer[i] = rx_buf[i];
    }

}

/* @ brief tx's a packet
 *
 *  Max length of packet is 120 for now due to crc and other stuff
 */
int rf_tx_packet_nonblocking(uint8_t *buf, uint8_t buf_len)
{
    int i;
    volatile uint8_t *tx_buf = &TRXFBST;

    if (buf_len >= RF_MAX_PACKET_LEN)
    {
        printf("packet too long\n");
        return RF_ERROR;
    }

    if (buf == NULL)
    {
        printf("packet can't be NULL\n");
        return RF_ERROR;
    }

    /* TODO: disable receiving here? */
    tx_buf[0] = buf_len;
    for (i = 1; i-1 < buf_len; i++)
    {
        tx_buf[i] = buf[i-1];
    }

    rf_trx_cmd(CMD_TX_START);

    return RF_SUCCESS;
}

void rf_rx_on(void)
{
    
}

/* @brief initializes rf
 */
void rf_init(void *rx_callback, void* tx_callback)
{
    g_rx_callback = rx_callback;
    g_tx_callback = tx_callback;

    // TODO: on-chip debug system must be disabled for best performance
    // TODO: install interrupt handlers
    rf_enable_int();

    printf("TRXFBST: %x\r\n", TRXFBST);
    printf("&TRXFBST: %x\r\n", (uint16_t) &TRXFBST);
}
