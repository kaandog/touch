
/* some includes */
#include <inttypes.h>
#include <avr/io.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <util/delay.h>
#include <stdio.h>
#include <math.h>
#define BAUD 115200
#include <util/setbaud.h>
#include "rf_touch.h"
#include "rf.h"

void uart_init(void) {
    UBRR0H = UBRRH_VALUE;
    UBRR0L = UBRRL_VALUE;

#if USE_2X
    UCSR0A |= _BV(U2X0);
#else
    UCSR0A &= ~(_BV(U2X0));
#endif

    UCSR0C = _BV(UCSZ01) | _BV(UCSZ00); /* 8-bit data */
    UCSR0B = _BV(RXEN0) | _BV(TXEN0);   /* Enable RX and TX */
}

void uart_putchar(char c) {
    loop_until_bit_is_set(UCSR0A, UDRE0); /* Wait until data register empty. */
    UDR0 = c;
}

char uart_getchar(void) {
    loop_until_bit_is_set(UCSR0A, RXC0); /* Wait until data exists. */
    return UDR0;
}

FILE uart_output = FDEV_SETUP_STREAM(uart_putchar, NULL, _FDEV_SETUP_WRITE);
FILE uart_input = FDEV_SETUP_STREAM(NULL, uart_getchar, _FDEV_SETUP_READ);
FILE uart_io = FDEV_SETUP_STREAM(uart_putchar, uart_getchar, _FDEV_SETUP_RW);

int main(void)
{
    char input;
    uint32_t cmd, data, dest_id;
    uint8_t buffer[128];
    uint8_t buf_i;

    // init uart
    uart_init();
    stdout = &uart_output;
    stdin  = &uart_input;

    touch_init(1);

    while(1)
    {
        buf_i = 0;
        input = getchar();
        while (input != '\n' && input != '\r' && buf_i < sizeof(buffer)) {
            buffer[buf_i++]= input;
            input = getchar();
        }
        buffer[buf_i++] = '\0';

        if (sscanf(buffer, " %c,%d,%d",&cmd, &data, &dest_id) != 3)
        {
            continue;
        }

        touch_tx_with_auto_retry((char)cmd, (int16_t)data, (uint8_t) dest_id, 3);


    }
}
