#include <inttypes.h>
#include <rf.h>
#include <rf_defs.h>
#include <rf_touch.h>
#include <stdio.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <avr/sleep.h>
#include <util/delay.h>

volatile uint8_t node_acks[MAX_NODES];
volatile touch_packet_t node_lp_cmds[MAX_NODES];
volatile uint8_t node_lp_stats[MAX_NODES];
volatile uint8_t low_power_mode = 0;

void low_power_on(void)
{
    low_power_mode = 1;
}

void low_power_off(void)
{
    low_power_mode=0;
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
    int16_t temp_OCR1A;
    touch_packet_t pkt;

    if (buf_len != sizeof(touch_packet_t))
    {
        DEBUG_PRINT("Invalid buf_len size %d\r\n", buf_len);

        return;
    }

    pkt = *((touch_packet_t*) buf);

    // if this packet isn't ours or is not from the gateway
    if (pkt.dest_node_id != NODE_ID || pkt.src_node_id != GATEWAY_ID)
    {
        return;
    }

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
        OCR1A = (uint16_t) temp_OCR1A;

        // send a packet back with our new servo pos
        touch_build_and_tx('i', (int16_t) (temp_OCR1A-133), GATEWAY_ID);

        // turn rx back on
        rf_rx_on();

        // delay until servo finishes rotation
        _delay_ms(100);
        servo_off();
    }
    else if (pkt.cmd == 'l')
    {
        touch_build_and_tx(CMD_ACK, 0, GATEWAY_ID);
        if (pkt.data)
        {
            low_power_on();
        }
        else
        {
            low_power_off();
        }
    }
    else if (pkt.cmd == CMD_ACK || pkt.cmd == CMD_INFO)
    {
        node_acks[pkt.src_node_id] = 1;
    }

    return;
}

void rx_gw_callback(uint8_t *buf, uint8_t buf_len)
{

    touch_packet_t pkt;
    if (buf_len != sizeof(touch_packet_t))
    {
        DEBUG_PRINT("Invalid buf_len size %d\r\n", buf_len);
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
    if (pkt.cmd == CMD_ACK || pkt.cmd == CMD_INFO)
    {
        // if this is an info packet
        if (pkt.cmd == CMD_INFO)
        {
            printf("p,%d,%d\n", pkt.data, pkt.src_node_id);
        }
        node_acks[pkt.src_node_id] = 1;
    }
    else if (pkt.cmd == CMD_WAKEUP)
    {
        // ack it and then send a cmd if one is available
        touch_build_and_tx(CMD_ACK, 0, pkt.src_node_id);
        // if there is a schedule command for this node, send it over
        if (node_lp_cmds[pkt.src_node_id].cmd != CMD_NOOP)
        {
            touch_tx_pkt(node_lp_cmds[pkt.src_node_id]);
            touch_schedule_cmd(CMD_NOOP, 0, pkt.src_node_id);
        }
    }
    else
    {
        printf("shouldn't be getting here!\n");
    }

    return;
}

/* @brief checks if char is a valid cmd
 */
uint8_t touch_is_valid_cmd(char cmd)
{
    if (cmd != CMD_LOWPOWER && cmd != CMD_INFO &&
        cmd != CMD_POSITION && cmd != CMD_MOVE &&
        cmd != CMD_WAKEUP && cmd != CMD_ACK &&
        cmd != CMD_INFO && cmd != CMD_NOOP)
    {
        return FALSE;
    }
    return TRUE;
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

uint8_t touch_tx_pkt(touch_packet_t pkt)
{
    if (!touch_is_valid_cmd(pkt.cmd))
    {
        return TOUCH_ERROR;
    }

    if (pkt.dest_node_id > MAX_NODES)
    {
        return TOUCH_ERROR;
    }

    DEBUG_PRINT("pkt.cmd = %c\r\n", pkt.cmd);
    DEBUG_PRINT("pkt.data = %d\r\n", pkt.data);
    DEBUG_PRINT("pkt.dest_node_id = %d\r\n", pkt.dest_node_id);
    DEBUG_PRINT("pkt.src_node_id = %d\r\n", pkt.src_node_id);

    rf_tx_packet_nonblocking((uint8_t*) &pkt, sizeof(touch_packet_t));
    return TOUCH_SUCCESS;

}

/* @brief builds and sends a touch packet
 */
uint8_t touch_build_and_tx(char cmd, int16_t data, uint8_t dest_id)
{
    touch_packet_t pkt;

    pkt.cmd = cmd;
    pkt.data = data;
    pkt.dest_node_id = dest_id;
    pkt.src_node_id = NODE_ID;

    return touch_tx_pkt(pkt);

}

/* @brief sends a touch packet and waits for ack
 */
uint8_t touch_tx_with_ack(char cmd, int16_t data, uint8_t dest_id)
{
    volatile uint8_t cnt = 0;
    if (touch_build_and_tx(cmd, data, dest_id) != TOUCH_SUCCESS)
    {
        return TOUCH_SUCCESS;
    }
    rf_rx_on();
    while(cnt++ < TIMEOUT_CNT)
    {
        _delay_ms(1);
        if (node_acks[dest_id])
        {
            DEBUG_PRINT("cnt: %d\r\n", cnt);
            node_acks[dest_id] = 0;
            return TOUCH_SUCCESS;
        }
    }
    node_acks[dest_id] = 0;
    return TOUCH_ERROR;
}


/* @brief schedules a command for a sleeping node
 */
uint8_t touch_schedule_cmd(char cmd, int16_t data, uint8_t dest_id)
{
    if (dest_id > MAX_NODES || !node_lp_stats[dest_id])
    {
        return TOUCH_ERROR;
    }

    if (!touch_is_valid_cmd(cmd))
    {
        return TOUCH_ERROR;
    }

    // atomically add this new packet
    cli();
    node_lp_cmds[dest_id].cmd = cmd;
    node_lp_cmds[dest_id].data = data;
    node_lp_cmds[dest_id].dest_node_id = dest_id;
    node_lp_cmds[dest_id].src_node_id = GATEWAY_ID;
    sei();

    return TOUCH_SUCCESS;
}

ISR(SCNT_CMP1_vect)
{
}

void tristate_ports(void)
{
    // Setup ports
    DDRB = 0;
    DDRG = 0;
    DDRD = 0;

    TCCR1A = 0;
    TCCR1B = 0;
    ICR1 = 0;
}

void setup_ports(void)
{
    // Setup ports
    DDRB |= (1<<5);
    DDRG |= (1<<0);
    DDRB |= (1<<2);
    DDRD |= (1<<4);

    TCCR1A|=(1<<COM1A1)|(1<<COM1B1)|(1<<WGM11);
    TCCR1B|=(1<<WGM13)|(1<<WGM12)|(1<<CS11)|(1<<CS10);
    ICR1=4999;
}


void enable_sc_wakeup(void)
{
    ASSR |= (1<<AS2);

    //sleep for 5 minutes
    SCOCR1HH = 0x01;
    SCOCR1HL = 0x2c;
    SCOCR1LH = 0x0;
    SCOCR1LL = 0x0;

    SCCNTHH = 0x0;
    SCCNTHL = 0x0;
    SCCNTLH = 0x0;
    SCCNTLL = 0x0;

    SCCR0 = (1<<SCEN) | (1<<SCCKSEL);
    while(SCSR & (1<<SCBSY));
    SCIRQM = (1<<IRQMCP1);
}

void disable_sc_wakeup(void)
{
    SCCR0 = 0;
    SCIRQM = 0;
}

void touch_node_main(void)
{
    cli();
    if (low_power_mode)
    {
        cli();

        led_on();
        // go to sleep
        rf_sleep();
        tristate_ports();
        enable_sc_wakeup();
        sei();
        set_sleep_mode(SLEEP_MODE_PWR_SAVE);
        sleep_enable();
        sleep_cpu();

        // wakeup
        sleep_disable();
        disable_sc_wakeup();
        setup_ports();
        rf_wake();
        if (touch_tx_with_auto_retry(CMD_WAKEUP, 0, GATEWAY_ID, 3))
        {
            led_on();
            _delay_ms(100);
            led_off();
            _delay_ms(100);
            led_on();
            _delay_ms(100);
            led_off();
        }

        // be responsive for 1 second
        // and go back to sleep
        // TODO: change back to 1 sec
        led_off();
        _delay_ms(3000);
    }
    sei();
}

void touch_gw_main(void)
{
    char input;
    uint32_t cmd, data, dest_id;
    uint8_t buffer[128];
    uint8_t buf_i;

    buf_i = 0;
    input = getchar();

    while (input != '\n' && input != '\r' && buf_i < sizeof(buffer)) {
        buffer[buf_i++]= input;
        input = getchar();
    }
    buffer[buf_i++] = '\0';

    if (sscanf(buffer, " %c,%d,%d",&cmd, &data, &dest_id) != 3)
    {
        return;
    }

    // invalid dest id
    if ((uint8_t)dest_id > MAX_NODES)
    {
        return;
    }

    // check if this is a low power command
    if ((char)cmd == CMD_LOWPOWER)
    {
        // low power on
        if (data)
        {
            if (!node_lp_stats[dest_id])
            {
                node_lp_stats[dest_id] = 1;
                touch_schedule_cmd(CMD_NOOP, 0, 0);
                touch_tx_with_auto_retry((char)cmd, (int16_t) data, (uint8_t) dest_id, 3);
            }
        }
        // low power off
        else
        {
            if (node_lp_stats[dest_id])
            {
                touch_schedule_cmd((char)cmd, (int16_t) data, (uint8_t) dest_id);
                node_lp_stats[dest_id] = 0;
            }
        }
        return;
    }

    if (node_lp_stats[dest_id])
    {
        if (cmd != CMD_LOWPOWER)
        {
            touch_schedule_cmd(cmd, data, dest_id);
        }
    }
    else
    {
        if (touch_tx_with_auto_retry((char)cmd, (int16_t)data, (uint8_t) dest_id, 3) != TOUCH_SUCCESS)
        {
            printf("e,%d\n", dest_id);
        }
    }
}

void touch_init(uint8_t is_gw)
{
    uint8_t i;
    for (i = 0; i < MAX_NODES; i++)
    {
        node_acks[i] = 0;
        node_lp_stats[i] = 0;
        node_lp_cmds[i].cmd = CMD_NOOP;
        node_lp_cmds[i].data = 0;
        node_lp_cmds[i].dest_node_id = 0;
        node_lp_cmds[i].src_node_id = 0;
    }
    if (is_gw)
        rf_init(rx_gw_callback, NULL);
    else
    {
        setup_ports();

        led_off();

        rf_init(rx_node_callback, NULL);
        rf_rx_on();

        // see if we are in low power mode
        touch_tx_with_auto_retry(CMD_QUESTION, 0, NODE_ID, 3);

    }
}
