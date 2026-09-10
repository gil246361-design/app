import { Component } from '@angular/core';
import { Router, RouterModule } from '@angular/router';

@Component({
  selector: 'app-member',
  imports: [RouterModule],
  templateUrl: './member.html',
  styleUrl: './member.css',
})
export class Member {
  constructor(private router: Router) { }
  changePage1() {
    this.router.navigate(['member', 'list']);
  }
  changePage2() {
    this.router.navigate(['/member/profile']);
  }
  sendParams() {
    this.router.navigate(['/member/test'], { queryParams: { userId: 1 } });
  }
}