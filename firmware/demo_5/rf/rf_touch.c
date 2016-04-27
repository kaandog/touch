#include <inttypes.h>
#include <rf.h>
#include <rf_defs.h>
#include <rf_touch.h>
#include <stdio.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <util/delay.h>

volatile uint8_t node_acks[MAX_NODES];

void low_power_on(void)
{
}

void low_power_off(void)
{
}

void servo_off(void)
{
    PORTG &= ~(1<<0);
}

void servo_on(void)
{
    PORTG |= (1<<0);
}

void led_on(void)
{
    PORTD &= ~(1<<4);
}

void led_off(void)
{
    PORTD |= (1<<4);
}

void rx_node_callback(uint8_t *buf, uint8_t buf_len)
{
    uint16_t temp_OCR1A;
    touch_packet_t pkt;

    if (buf_len != sizeof(touch_packet_t))
    {
        printf("Invalid buf_len size %d\r\n", buf_len);
        led_on();
        _delay_ms(100);
        led_off();
        _delay_ms(100);
        led_on();
        _delay_ms(100);
        led_off();

        return;
    }

    pkt = *((touch_packet_t*) buf);

    // if this packet isn't ours or is not from the gateway
    if (pkt.dest_node_id != NODE_ID || pkt.src_node_id != GATEWAY_ID)
    {
        return;
    }


    led_on();

    // if the command is for movement
    if (pkt.cmd == 'p' || pkt.cmd == 'm')
    {
        servo_on();
        if (pkt.cmd == 'p')
        {
            temp_OCR1A = pkt.data + 133;
        }
        else if (pkt.cmd == 'm')
        {
            temp_OCR1A = OCR1A;
            temp_OCR1A += pkt.data;
        }

        // make sure the OCR1A is bounded
        // to the servo's limits
        if (temp_OCR1A > 533)
        {
            temp_OCR1A = 533;
        }
        else if (temp_OCR1A < 133)
        {
            temp_OCR1A = 133;
        }
        OCR1A = temp_OCR1A;

        // send a packet back with our new servo pos
        touch_tx('i', (int16_t) (temp_OCR1A-133), GATEWAY_ID);

        // turn rx back on
        rf_rx_on();

        // delay until servo finishes rotation
        _delay_ms(500);
        servo_off();
    }
    else if (pkt.cmd == 'l')
    {

        if (pkt.data)
            low_power_on();
        else
            low_power_off();
    }


    led_off();

    return;
}

void rx_gw_callback(uint8_t *buf, uint8_t buf_len)
{

    touch_packet_t pkt;
    if (buf_len != sizeof(touch_packet_t))
    {
        printf("Invalid buf_len size %d\r\n", buf_len);
        return;
    }

    pkt = *((touch_packet_t*) buf);

    // if this packet isn't directed to us or is from us
    if (pkt.dest_node_id != GATEWAY_ID ||
        pkt.src_node_id == GATEWAY_ID ||
        pkt.src_node_id > MAX_NODES)
    {
        return;
    }

    // if packet is an ack packet
    if (pkt.cmd == 'a' || pkt.cmd == 'i')
    {
        // if this is an info packet
        if (pkt.cmd == 'i')
        {
            printf("%d:p,%d\r\n", pkt.src_node_id, pkt.data);
        }
        node_acks[pkt.src_node_id] = 1;
    }

    return;
}


/* @brief sends a packet with retry
 */
uint8_t touch_tx_with_auto_retry(char cmd, int16_t data, uint8_t dest_id, uint8_t max_retry_cnt)
{
    uint8_t cnt = 0;
    do {
        if (touch_tx_with_ack(cmd, data, dest_id) == TOUCH_SUCCESS)
        {
            return TOUCH_SUCCESS;
        }
    } while(cnt++ < max_retry_cnt);

    return TOUCH_ERROR;
}

/* @brief sends a touch packet
 */
uint8_t touch_tx(char cmd, int16_t data, uint8_t dest_id)
{
    touch_packet_t pkt;

    if (cmd != 'l' && cmd != 'i' && cmd != 'p' && cmd != 'm')
    {
        return TOUCH_ERROR;
    }

    if (dest_id > MAX_NODES)
    {
        return TOUCH_ERROR;
    }


    pkt.cmd = (char) cmd;
    pkt.data = (int16_t) data;
    pkt.dest_node_id = (uint8_t) dest_id;
    pkt.src_node_id = NODE_ID;

    printf("pkt.cmd = %c\r\n", pkt.cmd);
    printf("pkt.data = %d\r\n", pkt.data);
    printf("pkt.dest_node_id = %d\r\n", pkt.dest_node_id);
    printf("pkt.src_node_id = %d\r\n", pkt.dest_node_id);


    rf_tx_packet_nonblocking((uint8_t*) &pkt, sizeof(touch_packet_t));
    return TOUCH_SUCCESS;
}

/* @brief sends a touch packet and waits for ack
 */
uint8_t touch_tx_with_ack(char cmd, int16_t data, uint8_t dest_id)
{
    volatile uint8_t cnt = 0;
    if (touch_tx(cmd, data, dest_id) != TOUCH_SUCCESS)
    {
        return TOUCH_SUCCESS;
    }
    rf_rx_on();
    while(cnt++ < TIMEOUT_CNT)
    {
        _delay_ms(1);
        if (node_acks[dest_id])
        {
            printf("cnt: %d\r\n", cnt);
            node_acks[dest_id] = 0;
            return TOUCH_SUCCESS;
        }
    }
    node_acks[dest_id] = 0;
    return TOUCH_ERROR;
}

void touch_init(uint8_t is_gw)
{
    uint8_t i;
    for (i = 0; i < MAX_NODES; i++)
    {
        node_acks[i] = 0;
    }
    if (is_gw)
        rf_init(rx_gw_callback, NULL);
    else
    {
        // Setup ports
        DDRB |= (1<<5);
        DDRG |= (1<<0);
        DDRB |= (1<<2);
        DDRD |= (1<<4);

        TCCR1A|=(1<<COM1A1)|(1<<COM1B1)|(1<<WGM11);
        TCCR1B|=(1<<WGM13)|(1<<WGM12)|(1<<CS11)|(1<<CS10);
        ICR1=4999;

        led_off();

        rf_init(rx_node_callback, NULL);
        rf_rx_on();
    }
}
