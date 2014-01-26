#include <stdio.h>

int main(){
	int a = 100;
	int *p = &a;
	int *pp = p+1;
	printf("pp=%d,p=%d,p=%d\n",*pp,*p,*(p++));
}
