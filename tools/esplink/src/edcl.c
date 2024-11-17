//----------------------------------------------------------------------------
//  This file is a part of the VESPA SoC Prototyping Framework
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Apache 2.0 License.
//
// File:    edcl.vhd
// Authors: Gabriele Montanaro
//          Andrea Galimberti
//          Davide Zoni
// Company: Politecnico di Milano
// Mail:    name.surname@polimi.it
//
// This file was originally part of the ESP project source code, available at:
// https://github.com/sld-columbia/esp
//----------------------------------------------------------------------------

// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#include "edcl.h"

// Helper functions
static void print_progress(u64 progress, u64 total, const char *prefix)
{
	const u32 symbols = 40;
	int i;

	u64 percent = progress * 100 / total;

	u64 fraction = progress * symbols / total;

	printf("%s: [", prefix);

	for (i = 0; i < symbols; ++i) {
		char c = i < fraction ? '#' : ' ';
		printf("%c", c);
	}

	printf("] %lld%%", percent);
	if (progress == total)
		printf("\n");
	else
		printf("\r");
	fflush(stdout);
}

void set_sequence(u8 *_m, u32 _x)
{
	_m[2] = _m[2] | (u8) (0xff & ((_x << 2) >> 8));
	_m[3] = _m[3] | (u8) (0xff & ((_x << 2) >> 0));
}
struct sockaddr_in serv_addr, cli_addr;
static int s;

// new functions to send packets via UART

static void GM_set_start(u8 *_m)
{
	_m[0] |= (u8) (1 << 7);
}

static void GM_set_write(u8 *_m, u32 _x)
{
	_m[0] |= (u8) (_x << 6);
}

static void GM_set_len(u8 *_m, u32 _x)
{
	_m[0] |= (u8) _x;
}

static void GM_set_addr(u8 *_m, u32 _x)
{
	_m[1] = (u8) (0xff & (_x >> 24));
	_m[2] = (u8) (0xff & (_x >> 16));
	_m[3] = (u8) (0xff & (_x >> 8));
	_m[4] = (u8) (0xff & (_x >> 0));
}

static void GM_set_data(u8 *_m, u32 *_x, u32 _n)
{
	u32 i;
	for (i = 0; i < _n; i++) {
		u32 index = i * 4 + 5;
		_m[index + 0] = (u8) (0xff & (_x[i] >> 24));
		_m[index + 1] = (u8) (0xff & (_x[i] >> 16));
		_m[index + 2] = (u8) (0xff & (_x[i] >> 8));
		_m[index + 3] = (u8) (0xff & (_x[i] >> 0));
	}
}

static void GM_set_edcl_msg(u8 *buf, edcl_snd_t *msg)
{
	GM_set_start(buf);
	GM_set_write(buf, msg->write);
	GM_set_len(buf, msg->length/4 - 1);
	GM_set_addr(buf, msg->address);
	if (msg->write)
		GM_set_data(buf, msg->data, msg->length / 4);
	msg->msglen = (msg->write * msg->length);
}

//function that configures the serial port
static void conf_serial_port(int serial_port)
{
	// Create new termios struct, we call it 'tty' for convention
	// No need for "= {0}" at the end as we'll immediately write the existing
	// config to this struct
	struct termios tty;

	// Read in existing settings, and handle any error
	// NOTE: This is important! POSIX states that the struct passed to tcsetattr()
	// must have been initialized with a call to tcgetattr() overwise behaviour
	// is undefined
	if(tcgetattr(serial_port, &tty) != 0) {
		printf("Error %i from tcgetattr: %s\n", errno, strerror(errno));
	}

	tty.c_cflag &= ~PARENB; // Clear parity bit, disabling parity (most common)
	tty.c_cflag &= ~CSTOPB; // Clear stop field, only one stop bit used in communication (most common)
	tty.c_cflag &= ~CSIZE; // Clear all the size bits, then use one of the statements below
	tty.c_cflag |= CS8; // 8 bits per byte (most common)
	tty.c_cflag &= ~CRTSCTS; // Disable RTS/CTS hardware flow control (most common)
	tty.c_cflag |= CREAD | CLOCAL; // Turn on READ & ignore ctrl lines (CLOCAL = 1)

	tty.c_lflag &= ~ICANON;
	tty.c_lflag &= ~ECHO; // Disable echo
	tty.c_lflag &= ~ECHOE; // Disable erasure
	tty.c_lflag &= ~ECHONL; // Disable new-line echo
	tty.c_lflag &= ~ISIG; // Disable interpretation of INTR, QUIT and SUSP

	tty.c_iflag &= ~(IXON | IXOFF | IXANY); // Turn off s/w flow ctrl
	tty.c_iflag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL); // Disable any special handling of received bytes

	tty.c_oflag &= ~OPOST; // Prevent special interpretation of output bytes (e.g. newline chars)
	tty.c_oflag &= ~ONLCR; // Prevent conversion of newline to carriage return/line feed

	tty.c_cc[VTIME] = 1;    // Wait for up to 1s (10 deciseconds), returning as soon as any data is received.
	tty.c_cc[VMIN] = 0;

	cfsetispeed(&tty, B38400);
	cfsetospeed(&tty, B38400);

	// Save tty settings, also checking for error
	if (tcsetattr(serial_port, TCSANOW, &tty) != 0) {
		printf("Error %i from tcsetattr: %s\n", errno, strerror(errno));
	}

//	print_serial_conf(serial_port);

}
//
//function that convert a single packet in a u8 file and send it to the uart
static void handle_edcl_message(edcl_snd_t *snd, edcl_rcv_t *rcv)
{
//#ifdef VERBOSE
	int i = 0;
//#endif

	int serial_port = open("SERIAL_PORT", O_RDWR);

	conf_serial_port(serial_port);

	int iter = 0;
	u8 *buf_snd = calloc(BUFSIZE_MAX_SND, sizeof(u8));
	u8 *buf_rcv = malloc(BUFSIZE_MAX_RCV * sizeof(u8));
	//socklen_t clen = sizeof(struct sockaddr_in);

	// Prepare Ethernet packet payload
	GM_set_edcl_msg(buf_snd, snd);

	while (1) {
//#ifdef VERBOSE
		// Print message payload
		/*printf("Sending payload: ");
		for (i = 0; i < snd->msglen + 5; i++)
			printf("%02x ", buf_snd[i]);
		printf("\n");*/
//#endif
		//send the message
		int temp = write(serial_port, buf_snd, snd->msglen + 5);
		//printf("Write return value is %d.\n", temp);
		i = temp; //Dummy statement
		/* if (!snd->write) { */
		//clear the buffer by filling null, it might have previously received data
		memset(buf_rcv,'\0', BUFSIZE_MAX_RCV);

		int num_bytes = read(serial_port, buf_rcv, BUFSIZE_MAX_RCV);

		// n is the number of bytes read. n may be 0 if no bytes were received, and can also be -1 to signal an error.
		if (num_bytes < 0) {
			printf("Error reading: %s", strerror(errno));
			return;
		}

		//get_edcl_msg(buf_rcv, rcv);

//#ifdef VERBOSE
			// Print received message payload
			int payload_null = 1;
			for(i=0; i<rcv->msglen; i++)
				if(buf_rcv[i] != 0)
				{
					payload_null = 0;
					break;
				}
			if(!payload_null)
			{
				printf("Receiving payload: ");
				for (i = 0; i < rcv->msglen; i++)
					printf("%02x ", buf_rcv[i]);
				printf("\n");
			}
//#endif
			// Resend if necessary
			if (rcv->nack) {
				snd->sequence = rcv->sequence;
				set_sequence(buf_snd, snd->sequence);
				iter++;
			} else {
				break;
			}

			if (iter > 10)
				die("Error: Handle EDCL message failed after 10 attempts");
		/* } else { */
		/* 	break; */
		/* } */
	}

	free(buf_snd);
	free(buf_rcv);

	close(serial_port);
}


// EDCL API Functions
void die(char *s)
{
	perror(s);
	exit(EXIT_FAILURE);
}



//Set all the parameters for the uart (baud rate, parity bits, ecc.)
void connect_edcl(const char *server)
{
	printf("Connecting to serial port...\n");

	int serial_port = open("SERIAL_PORT", O_RDWR);

	// Check for errors
	if (serial_port < 0) {
		printf("Error %i from open: %s\n", errno, strerror(errno));
	}

	conf_serial_port(serial_port);

	close(serial_port);
}

void load_memory(char *fname)
{
	edcl_snd_t *snd = malloc(sizeof(edcl_snd_t));
	edcl_rcv_t *rcv = malloc(sizeof(edcl_rcv_t));
	u32 i;
	int r;
	u32 addr;
	FILE *fp = fopen(fname, "r");
	if (!fp)
		die("fopen");

	// First packet
	snd->offset = 0;
	snd->sequence = 0x0;
	snd->write = 1;


	while (1) {
		r = fscanf(fp, "%08x %08x\n", &snd->address, &snd->data[0]);

		if (r == EOF)
			break;

		if (r != 2)
			die("fscanf");

		for (i = 1; i < NWORD_MAX_SND; i++) {
			r = fscanf(fp, "%08x %08x\n", &addr, &snd->data[i]);
			if (r == EOF)
				break;
			if (r != 2)
				die("fscanf");
		}

		snd->length = i * 4;

		handle_edcl_message(snd, rcv);

		snd->sequence++;
	}

	fclose(fp);
	free(snd);
	free(rcv);
}

void dump_memory(u32 address, u32 size, char *fname)
{
	edcl_snd_t *snd = malloc(sizeof(edcl_snd_t));
	edcl_rcv_t *rcv = malloc(sizeof(edcl_rcv_t));
	u32 rem = size;
	u32 i;
	FILE *fp = fopen(fname, "w+");
	if (!fp)
		die("fopen");

	// First packet
	snd->offset = 0;
	snd->sequence = 0x0;
	snd->write = 0;
	snd->length = size < MAX_RCV_SZ ? size : MAX_RCV_SZ;
	snd->address = address;

	while (rem > 0) {
		handle_edcl_message(snd, rcv);

		for (i = 0; i < snd->length / 4; i++) {
			u32 addr = rcv->address + i * 4;
			u32 data = rcv->data[i];
			fprintf(fp, "%08x %08x\n", addr, data);
		}

		rem -= snd->length;

		snd->sequence++;
		snd->address += snd->length;
		snd->length = rem < MAX_RCV_SZ ? rem : MAX_RCV_SZ;
	}

	fclose(fp);
	free(snd);
	free(rcv);
}

//Function that send a file through the uart
void load_memory_bin(u32 base_addr, char *fname)
{
	edcl_snd_t *snd = malloc(sizeof(edcl_snd_t));
	edcl_rcv_t *rcv = malloc(sizeof(edcl_rcv_t));
	FILE *fp = fopen(fname, "rb");
	size_t sz;
	size_t rem;
	u32 i = 0;

	if (!fp)
		die("fopen");

	// Get binary size
	fseek(fp, 0L, SEEK_END);
	sz = ftell(fp);
	rewind(fp);
	rem = sz;
	printf("File size: %ld bytes\n", sz);
	// First packet
	snd->offset = 0;
	snd->sequence = 0x0;
	snd->write = 1;
	snd->address = base_addr;
	snd->length = rem < MAX_SND_SZ ? rem : MAX_SND_SZ;

	while (rem > 0) {
		if (lefread(&snd->data[0], sizeof(u32), snd->length / sizeof(u32), fp) != snd->length / sizeof(u32))
			die("fread");

		handle_edcl_message(snd, rcv);

		rem -= snd->length;
		i += snd->length / sizeof(u32);

		print_progress(sz - rem, sz, "loading binary");

		snd->address +=  snd->length;
		snd->length = rem < MAX_SND_SZ ? rem : MAX_SND_SZ;
		snd->sequence++;
	}

	fclose(fp);
	free(snd);
	free(rcv);

	/* clear_rcv_edcl(); */
	printf("Loaded %zu Bytes at %08x\n", sz, base_addr);
}

void dump_memory_bin(u32 address, u32 size, char *fname)
{
	edcl_snd_t *snd = malloc(sizeof(edcl_snd_t));
	edcl_rcv_t *rcv = malloc(sizeof(edcl_rcv_t));
	u32 rem = size;
	FILE *fp = fopen(fname, "wb+");
	if (!fp)
		die("fopen");

	// First packet
	snd->offset = 0;
	snd->sequence = 0x0;
	snd->write = 0;
	snd->length = size < MAX_RCV_SZ ? size : MAX_RCV_SZ;
	snd->address = address;

	while (rem > 0) {
		handle_edcl_message(snd, rcv);
		fwrite(&rcv->data[0], sizeof(u32), snd->length / sizeof(u32), fp);

		rem -= snd->length;

		print_progress(size - rem, size, "loading binary");

		snd->sequence++;
		snd->address += snd->length;
		snd->length = rem < MAX_RCV_SZ ? rem : MAX_RCV_SZ;
	}

	fclose(fp);
	free(snd);
	free(rcv);

	printf("Dumped %u Bytes starting at %08x\n", size, address);
}

void reset(u32 addr)
{
	edcl_snd_t *snd = malloc(sizeof(edcl_snd_t));
	edcl_rcv_t *rcv = malloc(sizeof(edcl_rcv_t));

	snd->offset = 0;
	snd->sequence = 0x0;
	snd->write = 1;
	snd->address = addr;
	snd->data[0] = 0x01;
	snd->length = 4;

	// Reset must be sent twice
	handle_edcl_message(snd, rcv);
	usleep(500000);

	free(snd);
	free(rcv);

	snd = malloc(sizeof(edcl_snd_t));
	rcv = malloc(sizeof(edcl_rcv_t));

	snd->offset = 0;
	snd->sequence = 0x0;
	snd->write = 1;
	snd->address = addr;
	snd->data[0] = 0x1;
	snd->length = 4;

	handle_edcl_message(snd, rcv);
	usleep(500000);

	free(snd);
	free(rcv);

	printf("Reset ESP processor cores\n");
}

void set_word(u32 addr, u32 data)
{
	edcl_snd_t *snd = malloc(sizeof(edcl_snd_t));
	edcl_rcv_t *rcv = malloc(sizeof(edcl_rcv_t));

	// First packet
	snd->offset = 0;
	snd->sequence = 0x0;
	snd->write = 1;
	snd->address = addr;
	snd->data[0] = data;
	snd->length = 4;

	handle_edcl_message(snd, rcv);

	free(snd);
	free(rcv);

	printf("Write %08x at %08x\n", data, addr);
}

void get_word(u32 addr)
{
	edcl_snd_t *snd = malloc(sizeof(edcl_snd_t));
	edcl_rcv_t *rcv = malloc(sizeof(edcl_rcv_t));

	// First packet
	snd->offset = 0;
	snd->sequence = 0x0;
	snd->write = 0;
	snd->address = addr;
	snd->length = 4;

	handle_edcl_message(snd, rcv);

	printf("Read %08x at %08x\n", rcv->data[0], addr);

	free(snd);
	free(rcv);
}

void disconnect_edcl()
{
	close(s);
}

// Function to receive data from the serial port
void listen_serial_port()
{
	int serial_port = open("SERIAL_PORT", O_RDWR);
	conf_serial_port(serial_port);
	char *buf_rcv = calloc(BUFSIZE_MAX_RCV, sizeof(u8));

	int num_bytes = 0;
	while(num_bytes == 0)
	{
		num_bytes = read(serial_port, buf_rcv, BUFSIZE_MAX_RCV);
	}
	// n is the number of bytes read. n may be 0 if no bytes were received, and can also be -1 to signal an error.
	if (num_bytes > 0) {
		printf("Incoming message: ");
		for(int i=0; i<num_bytes; i++)
			printf("%c", buf_rcv[i]);
		printf("\n");
		return;
	}

	free(buf_rcv);

	close(serial_port);
}
