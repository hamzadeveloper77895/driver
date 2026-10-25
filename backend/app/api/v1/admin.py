from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.models.entities import User, DriverProfile, Booking, Vehicle, PricingRule
import random

router = APIRouter(tags=["Admin"])


@router.get("/admin/stats")
async def get_admin_stats(db: AsyncSession = Depends(get_db)):
    total_users = (await db.execute(select(func.count(User.id)))).scalar() or 0
    total_drivers = (await db.execute(select(func.count(DriverProfile.id)))).scalar() or 0
    active_drivers = (await db.execute(select(func.count(DriverProfile.id)).where(DriverProfile.duty_status == "ONLINE"))).scalar() or 0
    total_bookings = (await db.execute(select(func.count(Booking.id)))).scalar() or 0
    active_trips = (await db.execute(select(func.count(Booking.id)).where(Booking.status.in_(["PENDING", "DRIVER_ASSIGNED", "ON_WAY", "ARRIVED", "IN_PROGRESS"])))).scalar() or 0
    sos_alerts = (await db.execute(select(func.count(Booking.id)).where(Booking.emergency_sos_triggered == True))).scalar() or 0

    return {
        "total_users": total_users,
        "total_drivers": total_drivers,
        "active_drivers_online": active_drivers,
        "total_bookings": total_bookings,
        "active_trips": active_trips,
        "emergency_sos_alerts": sos_alerts,
    }


@router.post("/admin/create-driver")
async def create_driver_action(
    full_name: str = Form(...),
    phone: str = Form(...),
    license_number: str = Form(...),
    experience_years: int = Form(3),
    can_drive_automatic: bool = Form(False),
    can_drive_manual: bool = Form(False),
    db: AsyncSession = Depends(get_db),
):
    clean_phone = phone.strip()
    if not clean_phone.startswith("+"):
        clean_phone = f"+91{clean_phone}"

    existing = (await db.execute(select(User).where(User.phone == clean_phone))).scalars().first()
    if not existing:
        user = User(
            phone=clean_phone,
            full_name=full_name.strip(),
            role="DRIVER",
            is_active=True,
        )
        db.add(user)
        await db.flush()

        profile = DriverProfile(
            user_id=user.id,
            license_number=license_number.strip().upper(),
            experience_years=experience_years,
            rating_average=5.0,
            total_trips=0,
            can_drive_manual=can_drive_manual or True,
            can_drive_automatic=can_drive_automatic or True,
            duty_status="ONLINE",
            current_lat=12.9716,
            current_lng=77.5946,
        )
        db.add(profile)
        await db.commit()

    return RedirectResponse(url="/admin?msg=Driver+Registered+Successfully", status_code=303)


@router.post("/admin/update-pricing")
async def update_pricing_action(
    city: str = Form("DefaultCity"),
    service_type: str = Form(...),
    base_hours: float = Form(2.0),
    base_fare: float = Form(25.0),
    extra_minute_rate: float = Form(0.20),
    night_charge_flat: float = Form(5.0),
    db: AsyncSession = Depends(get_db),
):
    existing = (await db.execute(select(PricingRule).where(PricingRule.service_type == service_type, PricingRule.city == city))).scalars().first()
    if existing:
        existing.base_hours = base_hours
        existing.base_fare = base_fare
        existing.extra_minute_rate = extra_minute_rate
        existing.night_charge_flat = night_charge_flat
    else:
        new_rule = PricingRule(
            city=city,
            service_type=service_type,
            base_hours=base_hours,
            base_fare=base_fare,
            extra_minute_rate=extra_minute_rate,
            night_charge_start_hour=22,
            night_charge_end_hour=6,
            night_charge_flat=night_charge_flat,
            surge_multiplier=1.0,
        )
        db.add(new_rule)

    await db.commit()
    return RedirectResponse(url="/admin?msg=Pricing+Rule+Updated+Successfully", status_code=303)


@router.get("/admin/dashboard", response_class=HTMLResponse)
@router.get("/admin", response_class=HTMLResponse)
async def admin_web_dashboard(request: Request, db: AsyncSession = Depends(get_db)):
    msg = request.query_params.get("msg", "")

    total_users = (await db.execute(select(func.count(User.id)))).scalar() or 0
    online_drivers = (await db.execute(select(func.count(DriverProfile.id)).where(DriverProfile.duty_status == "ONLINE"))).scalar() or 0
    active_trips = (await db.execute(select(func.count(Booking.id)).where(Booking.status.in_(["PENDING", "DRIVER_ASSIGNED", "ON_WAY", "ARRIVED", "IN_PROGRESS"])))).scalar() or 0
    completed_trips = (await db.execute(select(func.count(Booking.id)).where(Booking.status == "COMPLETED"))).scalar() or 0
    sos_alerts = (await db.execute(select(func.count(Booking.id)).where(Booking.emergency_sos_triggered == True))).scalar() or 0

    # Recent bookings
    b_res = await db.execute(select(Booking).order_by(Booking.created_at.desc()).limit(8))
    recent_bookings = b_res.scalars().all()

    # Drivers list
    d_res = await db.execute(select(User, DriverProfile).join(DriverProfile, User.id == DriverProfile.user_id).limit(10))
    drivers_data = d_res.all()

    # Pricing rules
    p_res = await db.execute(select(PricingRule))
    rules = p_res.scalars().all()

    bookings_html = ""
    for b in recent_bookings:
        status_color = "#10B981" if b.status == "COMPLETED" else ("#F59E0B" if b.status == "IN_PROGRESS" else ("#EF4444" if b.status == "CANCELLED" else "#6366F1"))
        bookings_html += f"""
        <tr style="border-bottom: 1px solid #1E293B;">
            <td style="padding: 12px; font-weight: 600; color: #818CF8;">{b.booking_code or b.id[:8]}</td>
            <td style="padding: 12px; color: #F8FAFC;">{b.pickup_address[:32]}...</td>
            <td style="padding: 12px; color: #94A3B8;">{b.service_type}</td>
            <td style="padding: 12px; font-weight: bold; color: #F8FAFC;">${(b.final_fare or b.estimated_fare or 0.0):.2f}</td>
            <td style="padding: 12px;">
                <span style="background: {status_color}22; color: {status_color}; padding: 4px 8px; border-radius: 6px; font-size: 11px; font-weight: bold;">
                    {b.status}
                </span>
            </td>
        </tr>
        """

    if not bookings_html:
        bookings_html = "<tr><td colspan='5' style='padding: 24px; text-align: center; color: #94A3B8;'>No bookings recorded yet. You can dispatch a booking or run the simulator.</td></tr>"

    drivers_html = ""
    for user, profile in drivers_data:
        duty_color = "#10B981" if profile.duty_status == "ONLINE" else "#94A3B8"
        trans = []
        if profile.can_drive_automatic: trans.append("Auto")
        if profile.can_drive_manual: trans.append("Manual")
        trans_str = "/".join(trans)

        drivers_html += f"""
        <div style="background: #1E293B; border-radius: 12px; padding: 12px; margin-bottom: 8px; display: flex; align-items: center; justify-content: space-between;">
            <div>
                <div style="font-weight: bold; color: #F8FAFC; font-size: 14px;">{user.full_name or 'Chauffeur Partner'}</div>
                <div style="font-size: 12px; color: #94A3B8;">{user.phone} • DL: {profile.license_number} ({trans_str})</div>
                <div style="font-size: 11px; color: #F59E0B; margin-top: 2px;">★ {profile.rating_average:.2f} • {profile.total_trips} trips</div>
            </div>
            <span style="background: {duty_color}22; color: {duty_color}; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: bold;">
                {profile.duty_status}
            </span>
        </div>
        """

    rules_html = ""
    for r in rules:
        rules_html += f"""
        <div style="background: #1E293B; border-radius: 12px; padding: 12px; margin-bottom: 8px;">
            <div style="font-weight: bold; color: #818CF8; font-size: 13px;">{r.service_type} ({r.city})</div>
            <div style="font-size: 12px; color: #F8FAFC; margin-top: 2px;">Base: ${r.base_fare:.2f} for {r.base_hours:.1f} hrs • Extra: ${r.extra_minute_rate:.2f}/min</div>
            <div style="font-size: 11px; color: #94A3B8;">Night Surcharge: +${r.night_charge_flat:.2f} (22:00–06:00)</div>
        </div>
        """

    msg_toast = f"""
    <div style="background: #065F46; border: 1px solid #10B981; color: #ECFDF5; padding: 12px 20px; border-radius: 12px; margin-bottom: 20px; font-size: 14px; font-weight: 600; display: flex; align-items: center; justify-content: space-between;">
        <span>✓ {msg}</span>
        <a href="/admin" style="color: #ECFDF5; text-decoration: none; font-size: 18px;">&times;</a>
    </div>
    """ if msg else ""

    html = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>ChauffeurX Admin Operations Portal</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700&display=swap" rel="stylesheet">
        <style>
            * {{ box-sizing: border-box; margin: 0; padding: 0; font-family: 'Outfit', sans-serif; }}
            body {{ background: #0B0F19; color: #F8FAFC; padding: 24px; }}
            .container {{ max-width: 1200px; margin: 0 auto; }}
            .header {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; }}
            .brand {{ font-size: 24px; font-weight: bold; color: #818CF8; display: flex; align-items: center; gap: 10px; }}
            .stats-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 24px; }}
            .stat-card {{ background: #1E293B; border: 1px solid rgba(255,255,255,0.06); border-radius: 16px; padding: 18px; }}
            .stat-val {{ font-size: 28px; font-weight: bold; margin-top: 6px; }}
            .stat-label {{ font-size: 12px; color: #94A3B8; text-transform: uppercase; letter-spacing: 0.5px; }}
            .grid-2 {{ display: grid; grid-template-columns: 1.8fr 1.2fr; gap: 24px; }}
            @media (max-width: 900px) {{ .grid-2 {{ grid-template-columns: 1fr; }} }}
            .panel {{ background: #131B2E; border: 1px solid rgba(255,255,255,0.06); border-radius: 18px; padding: 20px; margin-bottom: 24px; }}
            .panel-title {{ font-size: 16px; font-weight: bold; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; }}
            table {{ width: 100%; border-collapse: collapse; text-align: left; font-size: 13px; }}
            .badge-live {{ background: #10B981; color: white; padding: 2px 8px; border-radius: 12px; font-size: 10px; font-weight: bold; }}
            .btn {{ background: #6366F1; color: white; padding: 9px 18px; border-radius: 10px; text-decoration: none; font-size: 13px; font-weight: 600; border: none; cursor: pointer; }}
            .btn:hover {{ background: #4F46E5; }}
            input, select {{ width: 100%; background: #0B0F19; border: 1px solid #334155; color: #F8FAFC; padding: 10px 14px; border-radius: 10px; font-size: 13px; margin-top: 4px; margin-bottom: 12px; }}
            input:focus, select:focus {{ border-color: #6366F1; outline: none; }}
            label {{ font-size: 12px; color: #94A3B8; font-weight: 500; }}
            .form-grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }}
        </style>
    </head>
    <body>
        <div class="container">
            {msg_toast}
            <div class="header">
                <div class="brand">
                    <span>🛡️</span> ChauffeurX Admin Operations Portal
                </div>
                <div>
                    <a href="/docs" target="_blank" class="btn" style="background: #334155; margin-right: 8px;">Swagger API Docs</a>
                    <a href="/admin" class="btn">↻ Refresh Portal</a>
                </div>
            </div>

            <!-- Stats Bar -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-label">Active City Trips</div>
                    <div class="stat-val" style="color: #6366F1;">{active_trips}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Chauffeurs Online</div>
                    <div class="stat-val" style="color: #10B981;">{online_drivers}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Completed Rides</div>
                    <div class="stat-val" style="color: #0EA5E9;">{completed_trips}</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">Total Users</div>
                    <div class="stat-val" style="color: #F8FAFC;">{total_users}</div>
                </div>
                <div class="stat-card" style="border-color: rgba(239, 68, 68, 0.3);">
                    <div class="stat-label" style="color: #EF4444;">Emergency SOS</div>
                    <div class="stat-val" style="color: #EF4444;">{sos_alerts}</div>
                </div>
            </div>

            <div class="grid-2">
                <!-- Left Column: Forms & Live Ledger -->
                <div>
                    <!-- Form 1: Add New Driver -->
                    <div class="panel">
                        <div class="panel-title">
                            <span>➕ Register New Chauffeur</span>
                            <span style="font-size: 11px; color: #10B981;">Add to Driver Fleet</span>
                        </div>
                        <form action="/admin/create-driver" method="POST">
                            <div class="form-grid">
                                <div>
                                    <label>Driver Full Name</label>
                                    <input type="text" name="full_name" placeholder="e.g. Anand Kumar" required />
                                </div>
                                <div>
                                    <label>Phone Number</label>
                                    <input type="text" name="phone" placeholder="9876543299" required />
                                </div>
                            </div>
                            <div class="form-grid">
                                <div>
                                    <label>Driving License No.</label>
                                    <input type="text" name="license_number" placeholder="DL-04-2021-9988" required />
                                </div>
                                <div>
                                    <label>Experience (Years)</label>
                                    <input type="number" name="experience_years" value="4" min="1" max="40" required />
                                </div>
                            </div>
                            <div style="display: flex; gap: 20px; margin-bottom: 16px; align-items: center;">
                                <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; color: #F8FAFC;">
                                    <input type="checkbox" name="can_drive_automatic" checked style="width: auto; margin: 0;" /> Automatic Certified
                                </label>
                                <label style="display: flex; align-items: center; gap: 6px; cursor: pointer; color: #F8FAFC;">
                                    <input type="checkbox" name="can_drive_manual" checked style="width: auto; margin: 0;" /> Manual Certified
                                </label>
                            </div>
                            <button type="submit" class="btn" style="width: 100%;">Save & Activate Driver</button>
                        </form>
                    </div>

                    <!-- Live Bookings Ledger -->
                    <div class="panel">
                        <div class="panel-title">
                            <span>Live & Recent Ride Ledger</span>
                            <span class="badge-live">LIVE UPDATES</span>
                        </div>
                        <table>
                            <thead>
                                <tr style="color: #94A3B8; border-bottom: 1px solid #1E293B;">
                                    <th style="padding: 10px 12px;">Booking Code</th>
                                    <th style="padding: 10px 12px;">Pickup Route</th>
                                    <th style="padding: 10px 12px;">Package</th>
                                    <th style="padding: 10px 12px;">Fare</th>
                                    <th style="padding: 10px 12px;">Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                {bookings_html}
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Right Column: Pricing Form & Fleet Overview -->
                <div>
                    <!-- Form 2: Update Pricing Rule -->
                    <div class="panel">
                        <div class="panel-title">
                            <span>⚙️ Adjust Pricing Rates</span>
                        </div>
                        <form action="/admin/update-pricing" method="POST">
                            <label>Service Category</label>
                            <select name="service_type">
                                <option value="HOURLY_LOCAL">Hourly City Drive (Local)</option>
                                <option value="OUTSTATION_ROUND_TRIP">Outstation / Round Trip</option>
                            </select>
                            <div class="form-grid">
                                <div>
                                    <label>Base Package (Hours)</label>
                                    <input type="number" step="0.5" name="base_hours" value="2.0" required />
                                </div>
                                <div>
                                    <label>Base Fare ($)</label>
                                    <input type="number" step="0.5" name="base_fare" value="25.00" required />
                                </div>
                            </div>
                            <div class="form-grid">
                                <div>
                                    <label>Extra Rate ($/min)</label>
                                    <input type="number" step="0.05" name="extra_minute_rate" value="0.20" required />
                                </div>
                                <div>
                                    <label>Night Surcharge ($)</label>
                                    <input type="number" step="0.5" name="night_charge_flat" value="5.00" required />
                                </div>
                            </div>
                            <button type="submit" class="btn" style="width: 100%; background: #0EA5E9;">Update Pricing Rule</button>
                        </form>
                    </div>

                    <!-- Fleet Directory -->
                    <div class="panel">
                        <div class="panel-title">
                            <span>Active Chauffeur Fleet</span>
                            <span style="font-size: 11px; color: #94A3B8;">Verified Credentials</span>
                        </div>
                        {drivers_html}
                    </div>

                    <!-- Pricing Rules Card -->
                    <div class="panel">
                        <div class="panel-title">
                            <span>Active Rates Matrix</span>
                        </div>
                        {rules_html}
                    </div>
                </div>
            </div>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html)
