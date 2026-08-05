import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { AuthService } from './auth.service';

/** Blocks unauthenticated access to the admin shell. */
export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);
  return auth.isAuthenticated() ? true : router.parseUrl('/login');
};

/** Route-level permission gate (Section 3D — PermissionGuard('x')). */
export const permissionGuard = (code: string): CanActivateFn => {
  return () => {
    const auth = inject(AuthService);
    const router = inject(Router);
    if (!auth.isAuthenticated()) return router.parseUrl('/login');
    return auth.hasPermission(code) ? true : router.parseUrl('/unauthorized');
  };
};
