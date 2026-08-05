import { Directive, Input, TemplateRef, ViewContainerRef, effect, inject } from '@angular/core';

import { AuthService } from './auth.service';

/**
 * Structural directive — renders content only if the user holds the permission
 * (Section 3D). Removes from the DOM rather than hiding via CSS.
 *   <button *appHasPermission="'bookings.cancel'">Cancel</button>
 */
@Directive({ selector: '[appHasPermission]', standalone: true })
export class HasPermissionDirective {
  private tpl = inject(TemplateRef<unknown>);
  private vcr = inject(ViewContainerRef);
  private auth = inject(AuthService);

  private code = '';
  private rendered = false;

  constructor() {
    effect(() => {
      const allowed = this.auth.hasPermission(this.code);
      if (allowed && !this.rendered) {
        this.vcr.createEmbeddedView(this.tpl);
        this.rendered = true;
      } else if (!allowed && this.rendered) {
        this.vcr.clear();
        this.rendered = false;
      }
    });
  }

  @Input() set appHasPermission(code: string) {
    this.code = code;
  }
}
