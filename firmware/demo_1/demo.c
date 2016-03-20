
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

int main(void)
{
    char input;
    uart_init();
    stdout = &uart_output;
    stdin  = &uart_input;
    
    // Setup ports
    DDRB |= (1<<5);

    TCCR1A|=(1<<COM1A1)|(1<<COM1B1)|(1<<WGM11);        //NON Inverted PWM
    TCCR1B|=(1<<WGM13)|(1<<WGM12)|(1<<CS11)|(1<<CS10); //PRESCALER=64 MODE 14(FAST PWM)
    ICR1=4999;  //fPWM=50Hz (Period = 20ms Standard).
    _delay_ms(1000);
    while(1)
    {
        input = getchar();
        switch(input)
        {
            case '1':
                OCR1A = 100;
                break;
            case '2':
                OCR1A = 200;
                break;
            case '3':
                OCR1A = 316;
                break;
            case '4':
                OCR1A = 425;
                break;
            case '5':
                OCR1A = 535;
            case 'q':
                OCR1A = OCR1A-10;
                printf("OCR1A = %d\r\n", OCR1A);
                break;
            case 'w':
                OCR1A = OCR1A+10;
                printf("OCR1A = %d\r\n", OCR1A);
                break;
            default:
                break;
        }
    }
}
