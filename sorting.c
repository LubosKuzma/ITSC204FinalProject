#include <stdio.h>

// function to swap two elements
void swap(int *a, int *b)
{
    int temp = *a;
    *a = *b;
    *b = temp;
}

// function to implement cocktail sort
void cocktailSort(int arr[], int n)
{
    int start = 0;
    int end = n - 1;

    while (start <= end)
    {
        // move the smallest element to the left
        for (int i = start; i < end; i++)
        {
            if (arr[i] > arr[i+1])
            {
                swap(&arr[i], &arr[i+1]);
            }
        }
        end--;

        // move the largest element to the right
        for (int i = end; i > start; i--)
        {
            if (arr[i] < arr[i-1])
            {
                swap(&arr[i], &arr[i-1]);
            }
        }
        start++;
    }
}

// function to print the array
void printArray(int arr[], int n)
{
    for (int i = 0; i < n; i++)
    {
        printf("%d ", arr[i]);
    }
    printf("\n");
}

// main function
int main()
{
    // open the file
    FILE *fp = fopen("output.txt", "r");

    // read the number of elements
    int n;
    fscanf(fp, "%d", &n);

    // read the elements
    int arr[n];
    for (int i = 0; i < n; i++)
    {
        fscanf(fp, "%d", &arr[i]);
    }

    // sort the array
    cocktailSort(arr, n);

    // print the sorted array
    printArray(arr, n);

    // close the file
    fclose(fp);

    return 0;
}