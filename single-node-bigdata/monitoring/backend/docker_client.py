"""
Docker client for managing containers.
"""

import os
import logging
from typing import Dict, List, Optional, Any

import docker
from docker.errors import DockerException, NotFound, APIError

logger = logging.getLogger(__name__)


class DockerClient:
    """Client for interacting with Docker API."""
    
    def __init__(self):
        """Initialize Docker client."""
        try:
            self.client = docker.from_env()
            logger.info("Docker client initialized successfully")
        except DockerException as e:
            logger.error(f"Failed to initialize Docker client: {e}")
            self.client = None
    
    def _ensure_client(self):
        """Ensure Docker client is available."""
        if self.client is None:
            raise DockerException("Docker client not available")
    
    def get_container(self, container_name: str):
        """Get container by name."""
        self._ensure_client()
        try:
            return self.client.containers.get(container_name)
        except NotFound:
            logger.warning(f"Container not found: {container_name}")
            return None
        except APIError as e:
            logger.error(f"Docker API error: {e}")
            return None
    
    def get_container_status(self, container_name: str) -> Dict[str, Any]:
        """Get container status information."""
        container = self.get_container(container_name)
        
        if container is None:
            return {
                "name": container_name,
                "status": "not_found",
                "health": "unknown",
                "running": False
            }
        
        # Get container info
        container.reload()
        status = container.status
        
        # Get health status if available
        health = "unknown"
        if hasattr(container, 'attrs') and 'State' in container.attrs:
            state = container.attrs['State']
            if 'Health' in state:
                health = state['Health'].get('Status', 'unknown')
            elif status == 'running':
                health = 'healthy'
        
        return {
            "name": container_name,
            "id": container.short_id,
            "status": status,
            "health": health,
            "running": status == 'running',
            "created": container.attrs.get('Created', ''),
            "image": container.image.tags[0] if container.image.tags else 'unknown'
        }
    
    def get_all_containers(self, prefix: str = "") -> List[Dict[str, Any]]:
        """Get all containers, optionally filtered by name prefix."""
        self._ensure_client()
        
        try:
            containers = self.client.containers.list(all=True)
            result = []
            
            for container in containers:
                if prefix and not container.name.startswith(prefix):
                    continue
                
                result.append(self.get_container_status(container.name))
            
            return result
        except APIError as e:
            logger.error(f"Failed to list containers: {e}")
            return []
    
    def start_container(self, container_name: str) -> Dict[str, Any]:
        """Start a container."""
        container = self.get_container(container_name)
        
        if container is None:
            return {
                "success": False,
                "message": f"Container not found: {container_name}"
            }
        
        try:
            if container.status == 'running':
                return {
                    "success": True,
                    "message": f"Container {container_name} is already running"
                }
            
            container.start()
            container.reload()
            
            return {
                "success": True,
                "message": f"Container {container_name} started successfully",
                "status": container.status
            }
        except APIError as e:
            logger.error(f"Failed to start container {container_name}: {e}")
            return {
                "success": False,
                "message": f"Failed to start container: {str(e)}"
            }
    
    def stop_container(self, container_name: str, timeout: int = 10) -> Dict[str, Any]:
        """Stop a container gracefully."""
        container = self.get_container(container_name)
        
        if container is None:
            return {
                "success": False,
                "message": f"Container not found: {container_name}"
            }
        
        try:
            if container.status != 'running':
                return {
                    "success": True,
                    "message": f"Container {container_name} is not running"
                }
            
            container.stop(timeout=timeout)
            container.reload()
            
            return {
                "success": True,
                "message": f"Container {container_name} stopped successfully",
                "status": container.status
            }
        except APIError as e:
            logger.error(f"Failed to stop container {container_name}: {e}")
            return {
                "success": False,
                "message": f"Failed to stop container: {str(e)}"
            }
    
    def restart_container(self, container_name: str, timeout: int = 10) -> Dict[str, Any]:
        """Restart a container."""
        container = self.get_container(container_name)
        
        if container is None:
            return {
                "success": False,
                "message": f"Container not found: {container_name}"
            }
        
        try:
            container.restart(timeout=timeout)
            container.reload()
            
            return {
                "success": True,
                "message": f"Container {container_name} restarted successfully",
                "status": container.status
            }
        except APIError as e:
            logger.error(f"Failed to restart container {container_name}: {e}")
            return {
                "success": False,
                "message": f"Failed to restart container: {str(e)}"
            }
    
    def get_container_logs(
        self,
        container_name: str,
        tail: int = 100,
        since: Optional[int] = None
    ) -> Dict[str, Any]:
        """Get container logs."""
        container = self.get_container(container_name)
        
        if container is None:
            return {
                "success": False,
                "message": f"Container not found: {container_name}",
                "logs": ""
            }
        
        try:
            logs = container.logs(
                tail=tail,
                since=since,
                timestamps=True
            ).decode('utf-8', errors='replace')
            
            return {
                "success": True,
                "container": container_name,
                "logs": logs
            }
        except APIError as e:
            logger.error(f"Failed to get logs for {container_name}: {e}")
            return {
                "success": False,
                "message": f"Failed to get logs: {str(e)}",
                "logs": ""
            }


# Singleton instance
docker_client = DockerClient()
