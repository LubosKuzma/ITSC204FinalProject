// Counting sort in C programming

#include <stdio.h>

void countingSort(int array[], int size) {
  int output[10];

  // Find the largest element of the array
  int max = array[0];
  for (int i = 1; i < size; i++) 
  {
    if (array[i] > max)
      max = array[i];
  }


  int count[10];

  for (int i = 0; i < size; i++) {
    count[array[i]]++; 
  }
  // count[0] = 0
  // count[1] = 1   1  0   
  // count[2] = 2   3     
  // count[3] = 2   5  4    
  // count[4] = 1   6     
  // ...    
  // count[8] = 1   6     


[1, 0, 0, 3, 3, 0, 8]

  // Store the cummulative count of each array
  for (int i = 1; i <= max; i++) {
    count[i] += count[i - 1];
  }

  // Find the index of each element of the original array in count array, and
  // place the elements in output array
  for (int i = size - 1; i >= 0; i--) {
    output[count[array[i]] - 1] = array[i];
    count[array[i]]--;
  }


}

// Function to print an array
void printArray(int array[], int size) {
  for (int i = 0; i < size; ++i) {
    printf("%d  ", array[i]);
  }
  printf("\n");
}

// Driver code
int main() {
  int array[] = {4, 2, 2, 8, 3, 3, 1};

  int n = sizeof(array) / sizeof(array[0]);
  countingSort(array, n);
  printArray(array, n);
}