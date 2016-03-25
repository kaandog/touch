/** @file rf.h
 *  @brief rf header file
 */

#include "rf_defs.h"

int rf_tx_packet_nonblocking(uint8_t *buf, uint8_t buf_len);
void rf_change_state(uint8_t cmd);
void rf_init(void *rx_callback, void *tx_callback);
