
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

void adc_init(void)
{
    // Aref = AVcc
    ADMUX = (1<<REFS0);
    // ADC Enable and prescaler of 128
    // 16000000/128 = 125000
    ADCSRA = (1<<ADEN)|(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0);
}

uint16_t adc_read(uint8_t ch)
{
    // select the corresponding channel 0~7
    //   // ANDing with ’7′ will always keep the value
    //     // of ‘ch’ between 0 and 7
    ch &= 0b00000111;
    ADMUX = (ADMUX & 0xF8)|ch;

    // start single convertion
    //   // write ’1′ to ADSC
    ADCSRA |= (1<<ADSC);

    // wait for conversion to complete
    //   // ADSC becomes ’0′ again
    //     // till then, run loop continuously
    while(ADCSRA & (1<<ADSC));

    return (ADC);
}

void rx_callback()
{
    printf("SOMETHING WICKED THIS WAY COMES!\r\n");
    return;
}

int main(void)
{
    char input;
    uint8_t buffer[128];
    uint8_t buf_i;
    uint8_t len;
    touch_packet_t pkt;

    // init uart
    uart_init();
    stdout = &uart_output;
    stdin  = &uart_input;

    // Setup ports
    DDRB |= (1<<5);

    TCCR1A|=(1<<COM1A1)|(1<<COM1B1)|(1<<WGM11);
    TCCR1B|=(1<<WGM13)|(1<<WGM12)|(1<<CS11)|(1<<CS10);
    ICR1=4999;

    rf_init(rx_callback, NULL);

    while(1)
    {
        buf_i = 0;
        input = getchar();
        while (input != '\n' && input != '\r' && buf_i < sizeof(buffer)) {
            printf("%c", input);
            buffer[buf_i++]= input;
            input = getchar();
        }
        buffer[buf_i++] = '\0';
        printf("\r\n");

        printf("buffer:%s", buffer);
        sscanf(buffer, " %c,%d,%d",&pkt.cmd,&pkt.data,&pkt.node_id);

        printf("pkt.cmd = %c\r\n", pkt.cmd);
        printf("pkt.data = %d\r\n", pkt.data);
        printf("pkt.node_id = %d\r\n", pkt.node_id);

        rf_tx_packet_nonblocking((uint8_t*) &pkt, sizeof(touch_packet_t));
    }
}
