"""
Service routes for the monitoring API.
"""

import logging
from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db, Service, ServiceEvent
from docker_client import docker_client

logger = logging.getLogger(__name__)

router = APIRouter()

# Service configuration with web UI URLs
SERVICE_CONFIG = {
    "namenode": {
        "name": "NameNode",
        "service_type": "hadoop",
        "web_ui_url": "http://localhost:9870"
    },
    "datanode": {
        "name": "DataNode",
        "service_type": "hadoop",
        "web_ui_url": None
    },
    "resourcemanager": {
        "name": "ResourceManager",
        "service_type": "hadoop",
        "web_ui_url": "http://localhost:8088"
    },
    "nodemanager": {
        "name": "NodeManager",
        "service_type": "hadoop",
        "web_ui_url": "http://localhost:8042"
    },
    "historyserver": {
        "name": "HistoryServer",
        "service_type": "hadoop",
        "web_ui_url": "http://localhost:19888"
    },
    "spark-master": {
        "name": "Spark Master",
        "service_type": "spark",
        "web_ui_url": "http://localhost:8080"
    },
    "spark-worker": {
        "name": "Spark Worker",
        "service_type": "spark",
        "web_ui_url": "http://localhost:8081"
    },
    "hive-metastore": {
        "name": "Hive Metastore",
        "service_type": "hive",
        "web_ui_url": None
    },
    "hiveserver2": {
        "name": "HiveServer2",
        "service_type": "hive",
        "web_ui_url": "http://localhost:10002"
    },
    "mysql": {
        "name": "MySQL",
        "service_type": "database",
        "web_ui_url": None
    },
    "postgres": {
        "name": "PostgreSQL",
        "service_type": "database",
        "web_ui_url": None
    }
}


@router.get("")
async def list_services():
    """List all services with their current status."""
    services = []
    
    for container_name, config in SERVICE_CONFIG.items():
        status = docker_client.get_container_status(container_name)
        
        services.append({
            "container_name": container_name,
            "name": config["name"],
            "service_type": config["service_type"],
            "status": status.get("status", "unknown"),
            "health": status.get("health", "unknown"),
            "running": status.get("running", False),
            "web_ui_url": config["web_ui_url"]
        })
    
    return {"services": services}


@router.get("/{name}")
async def get_service(name: str):
    """Get details for a specific service."""
    if name not in SERVICE_CONFIG:
        raise HTTPException(status_code=404, detail=f"Service not found: {name}")
    
    config = SERVICE_CONFIG[name]
    status = docker_client.get_container_status(name)
    
    return {
        "container_name": name,
        "name": config["name"],
        "service_type": config["service_type"],
        "status": status.get("status", "unknown"),
        "health": status.get("health", "unknown"),
        "running": status.get("running", False),
        "web_ui_url": config["web_ui_url"],
        "container_id": status.get("id"),
        "image": status.get("image"),
        "created": status.get("created")
    }


@router.get("/{name}/health")
async def get_service_health(name: str):
    """Get health status for a specific service."""
    if name not in SERVICE_CONFIG:
        raise HTTPException(status_code=404, detail=f"Service not found: {name}")
    
    status = docker_client.get_container_status(name)
    
    return {
        "container_name": name,
        "name": SERVICE_CONFIG[name]["name"],
        "status": status.get("status", "unknown"),
        "health": status.get("health", "unknown"),
        "running": status.get("running", False)
    }


@router.post("/{name}/start")
async def start_service(name: str, db: AsyncSession = Depends(get_db)):
    """Start a service."""
    if name not in SERVICE_CONFIG:
        raise HTTPException(status_code=404, detail=f"Service not found: {name}")
    
    logger.info(f"Starting service: {name}")
    result = docker_client.start_container(name)
    
    # Record event in database
    try:
        # Find or create service record
        stmt = select(Service).where(Service.container_name == name)
        db_result = await db.execute(stmt)
        service = db_result.scalar_one_or_none()
        
        if service:
            event = ServiceEvent(
                service_id=service.id,
                event_type="start",
                event_data={"result": result}
            )
            db.add(event)
            
            # Update service status
            service.status = "running" if result.get("success") else service.status
            service.updated_at = datetime.utcnow()
            
            await db.commit()
    except Exception as e:
        logger.error(f"Failed to record event: {e}")
    
    if not result.get("success"):
        raise HTTPException(status_code=500, detail=result.get("message"))
    
    return result


@router.post("/{name}/stop")
async def stop_service(name: str, db: AsyncSession = Depends(get_db)):
    """Stop a service."""
    if name not in SERVICE_CONFIG:
        raise HTTPException(status_code=404, detail=f"Service not found: {name}")
    
    logger.info(f"Stopping service: {name}")
    result = docker_client.stop_container(name)
    
    # Record event in database
    try:
        stmt = select(Service).where(Service.container_name == name)
        db_result = await db.execute(stmt)
        service = db_result.scalar_one_or_none()
        
        if service:
            event = ServiceEvent(
                service_id=service.id,
                event_type="stop",
                event_data={"result": result}
            )
            db.add(event)
            
            # Update service status
            service.status = "stopped" if result.get("success") else service.status
            service.updated_at = datetime.utcnow()
            
            await db.commit()
    except Exception as e:
        logger.error(f"Failed to record event: {e}")
    
    if not result.get("success"):
        raise HTTPException(status_code=500, detail=result.get("message"))
    
    return result


@router.post("/{name}/restart")
async def restart_service(name: str, db: AsyncSession = Depends(get_db)):
    """Restart a service."""
    if name not in SERVICE_CONFIG:
        raise HTTPException(status_code=404, detail=f"Service not found: {name}")
    
    logger.info(f"Restarting service: {name}")
    result = docker_client.restart_container(name)
    
    # Record event in database
    try:
        stmt = select(Service).where(Service.container_name == name)
        db_result = await db.execute(stmt)
        service = db_result.scalar_one_or_none()
        
        if service:
            event = ServiceEvent(
                service_id=service.id,
                event_type="restart",
                event_data={"result": result}
            )
            db.add(event)
            service.updated_at = datetime.utcnow()
            await db.commit()
    except Exception as e:
        logger.error(f"Failed to record event: {e}")
    
    if not result.get("success"):
        raise HTTPException(status_code=500, detail=result.get("message"))
    
    return result


@router.get("/{name}/logs")
async def get_service_logs(
    name: str,
    tail: int = Query(default=100, ge=1, le=1000),
    since: Optional[int] = Query(default=None, description="Unix timestamp")
):
    """Get logs for a service."""
    if name not in SERVICE_CONFIG:
        raise HTTPException(status_code=404, detail=f"Service not found: {name}")
    
    result = docker_client.get_container_logs(name, tail=tail, since=since)
    
    if not result.get("success"):
        raise HTTPException(status_code=500, detail=result.get("message"))
    
    return {
        "container_name": name,
        "name": SERVICE_CONFIG[name]["name"],
        "logs": result.get("logs", "")
    }


@router.get("/{name}/events")
async def get_service_events(
    name: str,
    limit: int = Query(default=50, ge=1, le=200),
    db: AsyncSession = Depends(get_db)
):
    """Get recent events for a service."""
    if name not in SERVICE_CONFIG:
        raise HTTPException(status_code=404, detail=f"Service not found: {name}")
    
    try:
        # Get service
        stmt = select(Service).where(Service.container_name == name)
        result = await db.execute(stmt)
        service = result.scalar_one_or_none()
        
        if not service:
            return {"container_name": name, "events": []}
        
        # Get events
        stmt = (
            select(ServiceEvent)
            .where(ServiceEvent.service_id == service.id)
            .order_by(ServiceEvent.created_at.desc())
            .limit(limit)
        )
        result = await db.execute(stmt)
        events = result.scalars().all()
        
        return {
            "container_name": name,
            "name": SERVICE_CONFIG[name]["name"],
            "events": [e.to_dict() for e in events]
        }
    except Exception as e:
        logger.error(f"Failed to get events: {e}")
        raise HTTPException(status_code=500, detail=str(e))
