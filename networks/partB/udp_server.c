#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define MAX_CHUNK_SIZE 110
#define MAX_CHUNKS 100

typedef struct {
    int sequence_number;
    char data[MAX_CHUNK_SIZE];
} Chunk;

int main() {
    int sockfd;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_len = sizeof(client_addr);

    // Create UDP socket
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd == -1) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&server_addr, 0, sizeof(server_addr));
    memset(&client_addr, 0, sizeof(client_addr));

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(12345); // Choose any port you like

    // Bind socket to the server address
    if (bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1) {
        perror("Binding failed");
        exit(EXIT_FAILURE);
    }

    printf("UDP server listening on port %d\n", ntohs(server_addr.sin_port));

    int total_chunks=10;
    Chunk received_chunks[MAX_CHUNKS];
    int received_count = 0;

    recvfrom(sockfd, &total_chunks, sizeof(total_chunks), 0, (struct sockaddr *)&client_addr, &client_len);

    while (received_count < total_chunks) {
        Chunk chunk;
        recvfrom(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&client_addr, &client_len);

        // Simulate packet loss by not sending ACK for every chunk (skip every third chunk's ACK)
        // if (chunk.sequence_number % 3 != 0) {
            printf("Received Chunk %d\n", chunk.sequence_number);
            received_chunks[chunk.sequence_number] = chunk;
            received_count++;
        // }
    }

    printf("Received all chunks. Aggregating data:\n");
    for (int i = 0; i < total_chunks; i++) {
        printf("%s", received_chunks[i].data);
    }

    sendto(sockfd, &total_chunks, sizeof(total_chunks), 0, (struct sockaddr *)&client_addr, client_len);
    char input[1024];
    if (fgets(input, sizeof(input), stdin) == NULL) {
        perror("Input error");
        exit(1);
    }
    // Remove trailing newline character if present
    size_t len = strlen(input);
    for (int i = 0; i < total_chunks; i++) {
        Chunk chunk;
        chunk.sequence_number = i;
        for(int j=0;j<MAX_CHUNK_SIZE;j++)
        {
            chunk.data[j]=input[j+i*MAX_CHUNK_SIZE];
        }
        sendto(sockfd, &chunk, sizeof(chunk), 0, (struct sockaddr *)&client_addr, client_len);

        // if (i % 3 != 0) { // Simulate random ACK skipping
            printf("Sent Chunk %d\n", i);
        // }
        
        usleep(100000); // Sleep for 0.1 seconds to simulate delay
    }
    close(sockfd);
    return 0;
}
