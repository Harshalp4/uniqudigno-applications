import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';

import { AuthService } from './auth.service';

/** Adds Authorization + X-App-Source: admin to every API call (Section 7). */
export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const headers: Record<string, string> = { 'X-App-Source': 'admin' };
  if (auth.accessToken) headers['Authorization'] = `Bearer ${auth.accessToken}`;
  return next(req.clone({ setHeaders: headers }));
};
